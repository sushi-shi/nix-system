{ pkgs, claude-code, ... }:
{
  imports = [
    ./vim.nix
    ./fish.nix
  ];

  programs.mpv = {
    enable = true;
    scripts = [ pkgs.mpvScripts.mpris ];
    bindings = {
      "k" = "seek -15";
      "j" = "seek 15";
    };
  };

  services.lorri.enable = true;
  services.mpd.enable = true;
  services.mpd.musicDirectory = "/home/sheep/Music";

  home.packages = with pkgs; let
    utils = [
      claude-code.packages.${pkgs.system}.default

      comma         # Run command without installing it
      kalker        # command line calculator
      tokei         # count lines of code
      zathura

      # Tool to mirror websites.
      # I learned about it here: https://serverfault.com/questions/73962/wget-recursive-download-but-i-dont-want-to-follow-all-links
      # And I used it to mirror /u/ and /dt/ on dobrochan:
      # ```sh
      # httrack "https://old.dobrochan.net/archive/u/1.html" \
      # -O uni \
      # "-*" \
      # "+https://old.dobrochan.net/archive/u/*.html"
      # ```
      httrack

      jq            # Format JSON, echo '{ henlo: 'henlo' } | jq
      yt-dlp        # better youtube-dl
      gallery-dl    # download images from web

      pcre          # pcregrep: Perl regexes
      pass          # GPG encrypted password manager
      gnupg         # GPG itself
      wpa_supplicant_gui # wifi connecter

      gnome-sound-recorder # record my beautiful voice

      tealdeer      # better tldr
      file          # types of files
      atool         # Archive helper

      niv           # Nix autoupdate

      highlight     # ???
      gron          # greppable JSON

      pasystray     # moving PulseAudio sources/sinks
      parallel-full # execute jobs in parallel

      unrar unzip zip p7zip
      neofetch
      imagemagick
    ];

    apps = [
      element-desktop # Until nheko is fixed
      firefox
      tor-browser

      telegram-desktop
      signal-desktop # Secure telegram

      keepassxc
      anki-bin      # There is also anki package, but it is outdated

      ncmpcpp       # music player
      xournalpp     # drawing tool
    ];

    games = [];
    unfree = [];
    iphone = [];

    unused = [
      nheko         # Native Matrix client
      spotify
      jrnl          # diary

      teams-for-linux

      wineWowPackages.base
      libreoffice
      ghc
      (pkgs.callPackage ./pkgs/joshuto/default.nix {})
      (pkgs.callPackage ./pkgs/termusic/default.nix {})

      # games
      brogue
      wesnoth
      steam-run-native
      gzdoom

      # unfree
      haguichi
      logmein-hamachi
      slack
      tixati
      skypeforlinux
      discord
      atlassian-jira
      zoom-us

      # utils
      ripgrep-all   # greppable pdfs, images, subtitles, all
      clipit        # clipboard manager (worked poorly)
      openjdk8      # OS java implementation
      tldr          # man with examples
      dhcp
      qt5.qttools   # QT interface (TODO interface to what?)
      spotdl        # spotify-dl (from YouTube)
      epubcheck     # Tool for checking EPUB files

      # apps
      zulip          # OS slack!
      irssi         # IRC Channel
      tor-browser-bundle-bin # torproject.org is banned
      glade         # gtk3 interface designer
      vlc           # audio player

      # Iphone
      ifuse
      libimobiledevice
      usbmuxd

      # misc.
      protontricks
      protonup-ng

      ghidra

      libheif
      xplr
      ccls
      sqlx-cli
      postgresql_15
      wine
      (wine.override { wineBuild = "wine64"; })
      graphviz      # Graphs builder


      dbeaver       # Database viewer
      bash-completion
      texlive.combined.scheme-full
      grcov         # Parse files reporting test coverage
      onboard       # Virtual keyboard
      jmtpfs        # Connect android devices via MTP
      calibre       # Convert one text format into another easily
      ffsend        # Share files from CLI
      difftastic    # Smart diff utility
      wget
      paprefs       # multiple outputs
      entr          # run command on file update
      (ffmpeg.override {
      withXcb = true;
      })
      sd            # better sed
      gromit-mpx    # on-screen drawing
      xdot          # graph viewer

      cloc

      w3m wget cachix
      ctags
      entr
    ];

  in
    apps ++ utils ++ iphone ++ unfree ++ games;
}
