{ config, lib, ... }:
let
  cfg = config.my.system.notification;
in {
  options.my.system.notification = {
    enable = lib.mkEnableOption "Whether to enable notification daemon.";
    host = lib.mkOption {
      type = lib.types.str;
      description = "Host for notification server.";
      default = "127.0.0.1";
    };
    port = lib.mkOption {
      type = lib.types.port;
      description = "Port for notification server.";
      default = 16060;
    };
  };

  config = lib.mkIf cfg.enable {
    boot.enableContainers = true;
    containers.notification = {
      autoStart = true;

      config = {config, pkgs, lib, ...}: {
        imports = [ ../core/minimal.nix ];
        system.stateVersion = config.system.nixos.release;

        services.journald.extraConfig = ''
          SystemMaxUse=100M
        '';

        services.gotify = {
          enable = true;
          environment = {
            GOTIFY_DATABASE_DIALECT = "sqlite3";
            GOTIFY_SERVER_LISTENADDR = cfg.host;
            GOTIFY_SERVER_PORT = cfg.port;
            # Use reverse proxy for TLS termination
            GOTIFY_SERVER_SSL_ENABLED = "false";
            GOTIFY_SERVER_SSL_REDIRECTTOHTTPS = "false";
          };
        };
      };
    };
  };
}
