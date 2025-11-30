{ config, pkgs, lib, ... }:
let
  cfg = config.my.system.rss-feed;
  miniflux = pkgs.pure-unstable.miniflux;
in {
  options.my.system.rss-feed = {
    enable = lib.mkEnableOption "Whether to enable rss-feed daemon.";
    host = lib.mkOption {
      type = lib.types.str;
      description = "Host for rss-feed server.";
      default = "127.0.0.1";
    };
    port = lib.mkOption {
      type = lib.types.port;
      description = "Port for rss-feed server.";
      default = 16060;
    };
    adminCredentialsFile = lib.mkOption {
      type = lib.types.path;
      description = "Admin Credential File path.";
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.enableContainers = true;
    containers.rss-feed = {
      autoStart = true;

      bindMounts."/run/credentials/miniflux.service/env" = lib.mkIf (cfg.adminCredentialsFile != null) {
        hostPath = cfg.adminCredentialsFile;
        isReadOnly = true;
      };

      config = {config, pkgs, lib, ...}: {
        imports = [ ../core/minimal.nix ];
        system.stateVersion = config.system.nixos.release;

        services.journald.extraConfig = ''
          SystemMaxUse=100M
        '';

        services.miniflux = {
          enable = true;
          package = miniflux;
          createDatabaseLocally = true;
          adminCredentialsFile = if (cfg.adminCredentialsFile == null)
            then null else "/run/credentials/miniflux.service/env";
          config = {
            LISTEN_ADDR = "${cfg.host}:${toString cfg.port}";
          };
        };
      };
    };
  };
}
