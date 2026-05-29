{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ "dm-snapshot" "cryptd" ];

  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-label/NIXOS_LUKS";
    keyFile = "/dev/disk/by-id/usb-Samsung_Flash_Drive_FIT_0375425050002120-0:0-part2";
    keyFileSize = 4096;
    fallbackToPassword = true;
  };

  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=8G" "mode=755" ];
    };

  fileSystems."/var/log" =
    { device = "/nix/persist/var/log";
      fsType = "none";
      options = [ "bind" ];
      neededForBoot = true;
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-label/NIXOS_NIX";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-label/NIXOS_BOOT";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-label/NIXOS_HOME";
      fsType = "ext4";
    };

  fileSystems."/mnt/keepass_key" = {
    device = "/dev/disk/by-uuid/EDEE-5712";
    fsType = "exfat";
    options = [ "nofail" "noauto" "noexec" "umask=077" "uid=${toString config.users.users.sheep.uid}" "gid=${toString config.users.users.sheep.group}" "x-systemd.automount" ];
  };

  environment.etc."machine-id".source = "/nix/persist/etc/machine-id";

  swapDevices =
    [ { device = "/dev/disk/by-label/NIXOS_SWAP"; }
    ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.enableAllFirmware = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
