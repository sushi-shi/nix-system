{ pkgs, config, ... }:

{
   users = {
     users = {
       sheep = {
         isNormalUser = true;
         shell = pkgs.fish;
         extraGroups = [
           "wireshark"
           "wheel"           # sudo
           "networkmanager"
           "video"           # light
           "audio"           # ???
           "lp"              # printer
         ];
       };
    };
  };
}
