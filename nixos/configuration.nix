{
  config
  , pkgs
  , ...
}:

let
  packages = import ./packages.nix { inherit pkgs; };
in
{
  # Imports
  imports = [
      ./hardware-configuration.nix
      ./systemd-boot.nix
      ./users.julian.nix
      ./kde5.nix
    ];

  # Hostname
  networking.hostName = "nixos";

  # Timezone
  time.timeZone = "Australia/Perth";

  # Sound
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Users
  users.mutableUsers = false;

  # System
  environment = {
    shells = with packages; shells;
    systemPackages = with packages; system;
  };

  programs.vim.defaultEditor = true;
  fonts.fonts = packages.fonts;
  services.openssh.enable = true;
  system.copySystemConfiguration = true;
  system.stateVersion = "22.11";
}
