# Importing authentik-nix module is required for this module to work
{ config, pkgs, lib, ... }:
let
  cfg = config.my.system.auth;
in {
  options.my.system.auth = {
    enable = lib.mkEnableOption "Whether to enable auth.";
    host = lib.mkOption {
      type = lib.types.str;
      description = "Host address for auth server access.";
      default = "127.0.0.1";
    };
    port = lib.mkOption {
      type = lib.types.port;
      description = "Port for auth server.";
      default = 9000;
    };
    settings = lib.mkOption {
      type = lib.types.attrs;
      description = "Settings for auth server.";
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    services.authelia = cfg.settings;
  };
}
