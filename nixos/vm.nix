{ pkgs , ...  }:

let
  packages = import ./packages.nix { inherit pkgs; };
in
{
  # Imports
  imports = [
      ./hardware-configuration.nix
      ./common.nix
      ./sound.nix
      ./kde5.nix
      ./systemd-boot.nix
      ./users.julian.nix
    ];

  networking.hostName = "NixOS-VM";
  system.stateVersion = "22.11";
}
