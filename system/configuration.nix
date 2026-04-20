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

  services.xserver.enable = true;
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

    # Sysutils
    playerctl
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

    # Etc.
    torsocks
    keepassxc
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
      # "youtube.com" "www.youtube.com" "m.youtube.com" "youtu.be"
      "vk.com"      "www.vk.com"      "m.vk.com"
      "vkvideo.ru"  "www.vkvideo.ru"  "m.vkvideo.ru"
    ];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.11"; # Did you read the comment?
}
