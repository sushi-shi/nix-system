# sheep — NixOS configuration

Flake-based NixOS + home-manager config for the host `sheep`.

## Architecture

This is **not** a stock NixOS layout. Two things make it unusual:

- **Impermanence (tmpfs root).** `/` is a `tmpfs` living in RAM (8 GiB), so the
  entire root filesystem is **wiped on every reboot**. Anything the system needs
  to keep across boots must live on a persistent filesystem, under
  `/nix/persist` (see [Persistence](#persistence) below).
- **LVM-on-LUKS, unlocked by a USB keyfile.** The whole disk (except `/boot`)
  is a single LUKS container. Inside it is an LVM volume group holding `/nix`,
  `/home`, and swap. The container is unlocked automatically by a keyfile stored
  on a specific USB stick, with a passphrase fallback if the stick is absent.

### Disk layout

```
nvme0n1 (476.9 GiB)
├─ nvme0n1p1   1 GiB   vfat          NIXOS_BOOT   → /boot   (unencrypted EFI)
└─ nvme0n1p2 ~476 GiB  LUKS          NIXOS_LUKS   → cryptroot
   └─ cryptroot         LVM2 PV, VG = "lvmroot"
      ├─ lvmroot-swap   16 GiB  swap  NIXOS_SWAP  → [SWAP]
      ├─ lvmroot-root  128 GiB  ext4  NIXOS_NIX   → /nix
      └─ lvmroot-home  rest     ext4  NIXOS_HOME  → /home
```

Everything is addressed by **filesystem label** (`NIXOS_*`) in
`system/hardware-configuration.nix`, so the exact device names (`nvme0n1`, …)
don't matter as long as the labels match.

### Persistence

Because `/` is tmpfs, these are explicitly bind-mounted/persisted from `/nix`
(see `system/hardware-configuration.nix`):

- `/var/log`        ← `/nix/persist/var/log`
- `/etc/machine-id` ← `/nix/persist/etc/machine-id`

`/home` is its own LVM volume (not tmpfs), so user data survives reboots. If you
add system state that must survive (e.g. SSH host keys, wireguard keys), add a
bind mount the same way or adopt the [impermanence](https://github.com/nix-community/impermanence)
module.

### The USB keyfile

`boot.initrd.luks.devices."cryptroot"` reads the first **4096 bytes** of
**partition 2** of a USB stick as the LUKS key:

```nix
keyFile     = "/dev/disk/by-id/usb-Samsung_Flash_Drive_FIT_0375425050002120-0:0-part2";
keyFileSize = 4096;
fallbackToPassword = true;
```

- The `by-id` path is **specific to that exact Samsung FIT stick's serial.** A
  different stick → update `system/hardware-configuration.nix` accordingly.
- If the stick is missing/unreadable at boot, it falls back to prompting for the
  LUKS passphrase, so keep a passphrase enrolled too.

The **same** stick also carries an exfat partition (UUID `EDEE-5712`) auto-mounted
at `/mnt/keepass_key`, used to auto-open/close KeePassXC on plug/unplug (`udev`
rules in `system/configuration.nix`). So one physical stick does double duty:

- **partition 2** — raw bytes, the LUKS keyfile (unlocks the disk at boot)
- **exfat partition** (`EDEE-5712`) — holds the KeePassXC key file

## Secrets

The flake imports an **unencrypted** file outside the repo:

```nix
secrets.url = "path:/home/sheep/nixos/secrets.nix";
```

It must exist at `/home/sheep/nixos/secrets.nix` with this shape (wifi
networks, consumed by `networking.wireless.networks`):

```nix
{
  networks = {
    "My SSID"        = { psk = "plaintext-password"; };
    "Another SSID"   = { psk = "..."; };
  };
}
```

This file is **not** in git and must be recreated on a fresh install. The user
password is currently a `hashedPassword` committed in `system/user.nix`
(see [Improvements](#possible-improvements)).

---

## Fresh install / reinstall

Boot a NixOS live USB, then:

### 1. Partition the disk (GPT)

```sh
DISK=/dev/nvme0n1

parted "$DISK" -- mklabel gpt
parted "$DISK" -- mkpart ESP fat32 1MiB 1025MiB
parted "$DISK" -- set 1 esp on
parted "$DISK" -- mkpart primary 1025MiB 100%

# EFI boot partition
mkfs.fat -F32 -n NIXOS_BOOT "${DISK}p1"
```

### 2. Create the LUKS container

```sh
cryptsetup luksFormat "${DISK}p2"          # set a strong passphrase (the fallback)
cryptsetup config "${DISK}p2" --label NIXOS_LUKS
cryptsetup open "${DISK}p2" cryptroot      # unlock → /dev/mapper/cryptroot
```

### 3. Enroll the USB keyfile

The key USB holds two partitions: a small partition 2 for the raw LUKS key, and
an exfat partition (`EDEE-5712`) for the KeePassXC key. Write 4096 random bytes
into partition 2 and add those bytes as a LUKS key:

```sh
KEYDEV=/dev/sdX2          # the key USB's partition 2 — DOUBLE-CHECK THIS

dd if=/dev/urandom of=/tmp/luks.key bs=4096 count=1
cryptsetup luksAddKey "${DISK}p2" /tmp/luks.key --new-keyfile-size 4096
dd if=/tmp/luks.key of="$KEYDEV" bs=4096 count=1 conv=fsync
shred -u /tmp/luks.key
```

Then update the `by-id` path in `system/hardware-configuration.nix` to match the
new stick (`ls -l /dev/disk/by-id | grep usb`).

### 4. LVM inside the container

```sh
pvcreate /dev/mapper/cryptroot
vgcreate lvmroot /dev/mapper/cryptroot

lvcreate -L 16G  -n swap lvmroot
lvcreate -L 128G -n root lvmroot
lvcreate -l 100%FREE -n home lvmroot

mkswap  -L NIXOS_SWAP /dev/lvmroot/swap
mkfs.ext4 -L NIXOS_NIX  /dev/lvmroot/root
mkfs.ext4 -L NIXOS_HOME /dev/lvmroot/home
```

### 5. Mount with tmpfs root

```sh
mount -t tmpfs -o size=8G,mode=755 none /mnt

mkdir -p /mnt/{boot,nix,home}
mount /dev/disk/by-label/NIXOS_NIX  /mnt/nix
mount /dev/disk/by-label/NIXOS_HOME /mnt/home
mount /dev/disk/by-label/NIXOS_BOOT /mnt/boot
swapon /dev/disk/by-label/NIXOS_SWAP

# Persistent state dirs (must exist before first boot)
mkdir -p /mnt/nix/persist/var/log
mkdir -p /mnt/nix/persist/etc
mkdir -p /mnt/var/log            # bind target
```

### 6. Get the config + secrets in place

```sh
# Clone the repo to where the flake expects it
mkdir -p /mnt/home/sheep/nixos
git clone <this-repo-url> /mnt/home/sheep/nixos/nixfiles

# Recreate the secrets file (NOT in git — see Secrets section)
$EDITOR /mnt/home/sheep/nixos/secrets.nix
```

> The committed `system/hardware-configuration.nix` already matches this layout.
> Only regenerate it (`nixos-generate-config --root /mnt`) if the hardware
> changed — and if you do, re-apply the tmpfs/LUKS/persist bits, since the
> generator won't produce them.

### 7. Install

```sh
nixos-install --root /mnt --flake /mnt/home/sheep/nixos/nixfiles#sheep
reboot
```

The user password is set from `hashedPassword` in `system/user.nix`
(`mutableUsers = false`), so no `passwd` step is needed.

---

## Day-to-day

Convenience abbreviations are defined in `user/fish.nix`:

| abbr | command |
|------|---------|
| `nr` | `sudo nixos-rebuild switch --flake ~/nixos/nixfiles#` |
| `nu` | `sudo nix flake update --flake ~/nixos/nixfiles/flake.nix` |
| `ne` | edit `system/` config |
| `he` | edit `user/` (home-manager) config |
| `nq` | list system-wide installed packages |

## Repo layout

```
flake.nix                    inputs + nixosConfigurations.sheep
system/
  configuration.nix          system: boot, networking, niri, packages, services
  hardware-configuration.nix  disk/LUKS/LVM/tmpfs layout (edit on hardware change)
  user.nix                   user account + sudo
user/
  home.nix                   home-manager entry; copies config/ → ~/.config
  packages.nix               user packages (+ a large `unused` archive list)
  fish.nix  vim.nix          shell + neovim setup
  config/                    raw dotfiles copied into ~/.config
  scripts/                   helper scripts (added to PATH)
```

## Changing the username (`sheep`)

The username is defined **once** as `username = "sheep"` in `flake.nix` (the
`let` block) and threaded to every module via `specialArgs` (system) and
`home-manager.extraSpecialArgs` (home). To rename the user, change that one
line — plus the handful of exceptions below that can't reference it.

### Driven by the single `username` (change nothing else)

These all derive from the variable automatically:

| File | Uses `username` for |
|------|---------------------|
| `flake.nix` | `nixosConfigurations.${username}` and `home-manager.users.${username}` |
| `system/configuration.nix` | `networking.hostName` and `--machine=${username}@.host` (KeePass-autoclose udev rule) |
| `system/user.nix` | the account attr `users.${username}` and its `home = "/home/${username}"` |
| `system/hardware-configuration.nix` | `config.users.users.${username}.uid/.group` in the `/mnt/keepass_key` mount |
| `user/home.nix` | `home.username` and `home.homeDirectory` |
| `user/packages.nix` | `services.mpd.musicDirectory = "/home/${username}/Music"` |

> Host name and the `nixosConfigurations` attr are deliberately the same
> `username`, so `nixos-rebuild --flake .#` (which resolves to the hostname)
> keeps working after a rename.

### Exceptions — must still be edited by hand

These can't see the `username` let-binding (or aren't Nix-evaluated at all):

| File | Literal | Why it can't use the variable |
|------|---------|-------------------------------|
| `flake.nix` | `path:/home/sheep/nixos/secrets.nix` | flake `inputs` are resolved before `outputs`, so no access to the let-binding (also baked into `flake.lock` ×2). Could be dropped with a relative `path:../secrets.nix`. |
| `user/config/jrnl1` | `/home/sheep/journal.txt` | static JSON read by jrnl, no shell — must be Nix-templated to interpolate |
| `user/config/niri/config.kdl` | `/home/sheep/default.webp` | niri's plain `spawn-at-startup` has no shell; needs `spawn-sh-at-startup` or Nix templating |
| `flake.nix` | `description = "Sheep NixOS configuration"` | cosmetic |

### Shell scripts use `$HOME` (already username-independent)

`user/config/ranger/scope.sh`, `user/scripts/swayidle_start`, and the
`user/scripts/unused/*` archive use `$HOME`; `home.sessionPath` and the
`fish.nix` abbreviations use `$HOME` / `~`.

**Caveat:** `$HOME`/`~` only expand when a shell actually evaluates the string,
and `~` further requires being unquoted and leading — so in these quoted
contexts use **`$HOME`, not `~`**. Anywhere without a shell in the loop (niri
`spawn`, the `jrnl`/KDL dotfiles above) the literal stays and must be
Nix-templated or routed through `sh`.
