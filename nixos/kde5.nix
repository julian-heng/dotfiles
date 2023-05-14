{
  services
  , pkgs
  , ...
}:

{
  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
    desktopManager.plasma5 = {
      enable = true;
      excludePackages = with pkgs.libsForQt5; [
        plasma-browser-integration
        oxygen
        elisa
        khelpcenter
      ];
    };
  };
}
