{ pkgs, ...  }:

let
  packages = import ./packages.nix { inherit pkgs; };
in
{
  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
    desktopManager.plasma5.enable = true;
  };
  environment.plasma5.excludePackages = with pkgs.libsForQt5; [
    plasma-browser-integration
    oxygen
    elisa
    khelpcenter
  ];
  fonts.fonts = packages.fonts;
}
