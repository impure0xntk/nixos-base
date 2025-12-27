{ config, pkgs, lib, ... }:
let
  cfg = config.my.system.task-management;
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
  };

  config = lib.mkIf cfg.enable {
    services.vikunja = {
      enable = true;
      port = cfg.port;
      frontendHostname = cfg.host;
      frontendScheme = "http";
    };
  };
}
