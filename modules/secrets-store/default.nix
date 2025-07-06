{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.types;
let
  cfg = config.my.system.secrets-store;
  cfgDevUser = config.my.system.users.devUsers;
in
{
  options.my.system.secrets-store = {
  };

  config = {
    sops = {
      age = {
        generateKey = true;
        keyFile = "/var/lib/sops-nix/key.txt";
      };
    };
  };
}
