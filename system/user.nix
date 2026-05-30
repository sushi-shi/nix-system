{ pkgs, config, username, ... }:

{
   users = {
     mutableUsers = false;

     users = {
       ${username} = {
         uid = 1000;
         hashedPassword = "$6$W2LaRTukeUzmz8FQ$JvWYiWJ3s1y5lENzZXuw5f7DisgcYSNNVq/1ovmjgEKOxj/Qr3UxS7IPd.9jFuXFALdrnF7XBoPZyeqdVAk4M/";
         home = "/home/${username}";
         createHome = true;
         isNormalUser = true;
         shell = pkgs.fish;
         extraGroups = [
           "wireshark"       # packet capture
           "wheel"           # sudo
           "networkmanager"  # network connections
           "video"           # display devices (screen)
           "input"           # input devices (keyboard)
           "lp"              # printer
         ];
       };
    };
  };
  security.sudo.extraConfig = ''
    Defaults lecture=never
  '';
}
