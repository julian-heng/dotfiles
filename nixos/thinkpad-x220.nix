{ pkgs , ...  }:

let
  packages = import ./packages.nix { inherit pkgs; };
in
{
  # Imports
  imports = [
      <nixos-hardware/lenovo/thinkpad/x220>
      ./hardware-configuration.nix
      ./common.nix
      ./sound.nix
      ./kde5.nix
      ./systemd-boot.nix
      ./users.julian.nix
      ./wifi.nix
    ];

  networking.hostName = "ThinkPad-X220";
  system.stateVersion = "22.11";
}
