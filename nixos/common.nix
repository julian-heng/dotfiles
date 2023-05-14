{ pkgs, ... }:

let
  packages = import ./packages.nix { inherit pkgs; };
in
{
  # Timezone
  time.timeZone = "Australia/Perth";

  # Users
  users.mutableUsers = false;

  # System
  environment = {
    shells = with packages; shells;
    systemPackages = with packages; system;
  };

  programs.vim.defaultEditor = true;
  services.openssh.enable = true;
  system.copySystemConfiguration = true;
}
