{ config, pkgs, lib, ... }:
let
  cfg = config.my.system.task-management;

  package = pkgs.vikunja-unstable; # For 1.y.z
in {
  options.my.system.task-management = {
    enable = lib.mkEnableOption "Whether to enable task-management.";
    host = lib.mkOption {
      type = lib.types.str;
      description = "Host address for task-management server access.";
      default = "127.0.0.1";
    };
    port = lib.mkOption {
      type = lib.types.port;
      description = "Port for task-management server.";
      default = 8080;
    };
    settings = lib.mkOption {
      type = lib.types.attrs;
      description = "Additional settings for task-management.";
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    services.vikunja = {
      enable = true;
      port = cfg.port;
      frontendHostname = cfg.host;
      frontendScheme = "http";
      inherit package;
    } // cfg.settings;
  };
}
