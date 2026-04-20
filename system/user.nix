{ pkgs, config, ... }:

{
   users = {
     users = {
       sheep = {
         hashedPassword = "$6$W2LaRTukeUzmz8FQ$JvWYiWJ3s1y5lENzZXuw5f7DisgcYSNNVq/1ovmjgEKOxj/Qr3UxS7IPd.9jFuXFALdrnF7XBoPZyeqdVAk4M/";
         home = "/home/sheep";
         isNormalUser = true;
         shell = pkgs.fish;
         extraGroups = [
           "wireshark"       # packet capture
           "wheel"           # sudo
           "networkmanager"  # network connections
           "video"           # display devices
           "lp"              # printer
         ];
       };
    };
  };
  security.sudo.extraConfig = ''
    Defaults lecture=never
  '';
}
