{ networking, ... }:

{
  networking.wireless.iwd.enable = true;
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
  };
}
