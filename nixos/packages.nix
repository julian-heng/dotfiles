{ pkgs, ...}:

with pkgs; rec {
  # Package Categories
  textEditors = [
    vim
  ];

  guiTextEditors = [
    # sublime
  ];

  vcs = [
    gitAndTools.gitFull
  ];

  terminals = [
    konsole
  ];

  fonts = [
    ibm-plex
    inconsolata
  ];

  programming = [
    clang
    cmake
    dotnet-sdk
    gcc
    gnumake
    nodejs
    python3Minimal
    rustup
  ];

  shells = [
    bash
  ];

  themes = [
    breeze-gtk
    papirus-icon-theme
  ];

  web = [
    # discord
    firefox
    thunderbird
    transmission
  ];

  graphics = [
    blender
    kolourpaint
    krita
  ];

  multimedia = [
    audacity
    cmus
    ffmpeg
    handbrake
    mpv
    obs-studio
    youtube-dl
  ];

  office = [
    ark
    dolphin
    gwenview
    kcalc
    nextcloud-client
    okular
  ];

  security = [
    gnupg
    keepassxc
  ];

  systemAdmin = [
    curl
    htop
    inxi
    ncdu
    neofetch
    parted
    pciutils
    tmux
    tree
    usbutils
    wget
  ];

  guiSystemAdmin = [
    partition-manager
  ];

  # Package Groups
  dev =
    textEditors
    ++ guiTextEditors
    ++ vcs
    ++ terminals
    ++ programming
  ;

  desktop =
    web
    ++ graphics
    ++ multimedia
    ++ office
    ++ security
    ++ terminals
    ++ themes
  ;

  user =
    dev
    ++ desktop
    ++ systemAdmin
    ++ guiSystemAdmin
  ;

  system =
    textEditors
    ++ shells
    ++ systemAdmin
  ;
}
