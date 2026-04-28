{ config, lib, pkgs, pkgs-unstable, secrets, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./user.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "sheep"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  # networking.networkmanager.enable = true;
  networking.interfaces.enp1s0.useDHCP = true;
  networking.interfaces.wlp2s0.useDHCP = true;
  networking.wireless = {
    enable = true;
    networks = secrets.networks;
    extraConfig = ''
      ctrl_interface=/run/wpa_supplicant
      ctrl_interface_group=wheel
    '';
  };

  time.timeZone = "Europe/Poland";

  services.xserver.xkb = {
    layout = "pl,ru-by";

    options = "caps:swapescape,grp:alt_shift_toggle";

    extraLayouts.ru-by = {
      description = "Russian with Belarusian ў and і";
      languages = [ "rus" ];
      symbolsFile = pkgs.writeText "xkb-ru-by" ''
        partial alphanumeric_keys modifier_keys
        xkb_symbols "ru-by" {
            include "ru"
            name[Group1] = "Russian (Belarusian extras)";

            replace key <AD03> { [ Cyrillic_u, Cyrillic_U, U045E, U040E ] };
            replace key <AD05> { [ Cyrillic_ie, Cyrillic_IE, Cyrillic_io, Cyrillic_IO ] };
            replace key <AD09> { [ Cyrillic_u, Cyrillic_U, U045E, U040E ] };
            replace key <AD12> { [ Cyrillic_hardsign, Cyrillic_HARDSIGN, apostrophe, quotedbl ] };
            replace key <AB05> { [ Cyrillic_i, Cyrillic_I, U0456, U0406 ] };
        };
      '';
    };
  };
  # caps:swapescape in tty
  # `console.useXkbConfig` is broken. Because of Cyrillic replacements, 'be]' characters are no longer printed.
  console.keyMap = pkgs.writeText "us-caps-esc.map" ''
    include "${pkgs.kbd}/share/keymaps/i386/qwerty/us.map.gz"
    keycode 58 = Escape
    keycode 1  = Caps_Lock
  '';

  services.displayManager.gdm.enable = true;

  programs.niri = {
    enable = true;
    package = pkgs-unstable.niri;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.sheep = {
    isNormalUser = true;
    createHome = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  programs.bandwhich.enable = true;
  programs.neovim.enable = true;
  programs.neovim.defaultEditor = true;

  programs.fish.enable = true;
  programs.htop.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    # Niri environment
    mako
    fuzzel
    waybar
    swaybg
    swayidle
    swaylock-effects
    swayimg
    xwayland-satellite

    # Terminal
    starship
    alacritty ranger
    ncdu
    bat eza tree
    fzf ripgrep
    git direnv

    keepassxc

    # Sysutils
    lshw          # list hardware
    lsof
    lsscsi
    mtr           # traceroute, ping
    psmisc
    sysstat       # iostat, pidstat

    binutils
    pciutils
    usbutils      # lsusb and similar

    ntfs3g        # mounting ntfs stuff
    go-mtpfs      # connect Android devices
    inotify-tools

    upower
    tlp
    linuxPackages.cpupower

    libnotify     # dbus notifications
    libinput      # lists input devices
    evtest        # I use it to disable keyboard :)
  ];

  services.udev.extraRules = ''
    SUBSYSTEM=="block", ENV{ID_VENDOR_ID}=="04e8", ENV{ID_MODEL_ID}=="6300", ACTION=="add", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}="keepass-autoopen.service"
    SUBSYSTEM=="block", ENV{ID_VENDOR_ID}=="04e8", ENV{ID_MODEL_ID}=="6300", ACTION=="remove", RUN+="${pkgs.systemd}/bin/systemctl --user --machine=sheep@.host start keepass-autoclose.service"
  '';

  systemd.user.services.keepass-autoopen = {
    description = "Auto-open KeePassXC on USB plug";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/run/current-system/sw/bin/keepassxc";
    };
  };

  systemd.user.services.keepass-autoclose = {
    description = "Auto-close KeePassXC on USB removal";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/run/current-system/sw/bin/pkill keepassxc";
    };
  };

  networking.hosts = {
    "0.0.0.0" = [
      "youtube.com" "www.youtube.com" "m.youtube.com" "youtu.be"
      "vk.com"      "www.vk.com"      "m.vk.com"
      "vkvideo.ru"  "www.vkvideo.ru"  "m.vkvideo.ru"
    ];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.11"; # Did you read the comment?
}
