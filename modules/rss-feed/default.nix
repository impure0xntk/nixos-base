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
    settings = lib.mkOption {
      type = lib.types.attrs;
      description = "Additional settings for rss-feed.";
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    services.miniflux = {
      enable = true;
      package = miniflux;
      config = {
        CREATE_ADMIN = lib.mkDefault false;
        LISTEN_ADDR = "${cfg.host}:${toString cfg.port}";
      } // cfg.settings;
    };
  };
}
