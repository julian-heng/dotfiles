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
    ./users.julian.password.nix
  ];

  users.users.julian = {
    isNormalUser = true;
    description = "julian";
    extraGroups = [ "wheel" ];
    packages = with packages; user;
    shell = pkgs.bash;
  };
}
