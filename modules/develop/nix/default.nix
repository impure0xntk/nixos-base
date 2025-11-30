{ config, pkgs, lib, ... }:
let
  cfg = config.my.system.develop.nix;
  cfgDevUser = config.my.system.users.devUsers;
in {
  options = {
    my.system.develop.nix = {
      enable = lib.mkEnableOption "Whether to enable nix development environment setup";
    };
  };

  config = {
    assertions = [
      {
        assertion = ! (cfg.enable && (builtins.length cfgDevUser) == 0);
        message = "Couldn't find Development users.";
      }
    ];
    # By default, lix is enabled for all.
    # Ensure it's enabled only when cfg.enable as developer environment is true.
    lix.enable = cfg.enable;
    # For nix-index. by default programs.nix-index.enable = lib.mkDefault true;
    # https://github.com/nix-community/nix-index-database/blob/main/nix/shared.nix
    programs.nix-index.enable = cfg.enable;
    programs.nix-index-database.comma.enable = cfg.enable;
  };
}
