{
  pkgs
  , users
  , modulesPath
  , secrets
  , lib
  , ...
}:

let
  packages = import ./packages.nix { inherit pkgs; };
in
{
  imports = [
    <home-manager/nixos>
    ./users.julian.password.nix
  ];

  users.users.julian = {
    isNormalUser = true;
    description = "julian";
    extraGroups = [ "wheel" ];
    packages = with packages; user;
    shell = pkgs.bash;
  };

  home-manager.users.julian = { ... }: {
    home.stateVersion = "22.11";
    programs.git = {
      enable = true;
      userName = "julian-heng";
      userEmail = "julianhengwl@gmail.com";
    };

    programs.bash = {
      enable = true;
      enableCompletion = true;
      bashrcExtra =
        "distro=nixos\n"
        + builtins.readFile ./dotfiles/bashrc/modules/colours
        + builtins.readFile ./dotfiles/bashrc/modules/aliases
        + builtins.readFile ./dotfiles/bashrc/modules/env_var
        + builtins.readFile ./dotfiles/bashrc/modules/functions
        + builtins.readFile ./dotfiles/bashrc/modules/prompt
      ;
    };

    programs.readline = {
      enable = true;
      extraConfig = builtins.readFile ./dotfiles/bashrc/inputrc_linux;
    };

    programs.tmux = {
      enable = true;
      extraConfig = builtins.readFile ./dotfiles/tmux/tmux.conf;
    };

    programs.vim = {
      enable = true;
      defaultEditor = true;
      extraConfig = builtins.readFile ./dotfiles/vimrc/vimrc;
      plugins = with pkgs.vimPlugins; [
        indentLine
        lightline-vim
        tabular
        vim-lsc
        vim-nix
        vim-repeat
        vim-surround
      ];
    };
  };
}
