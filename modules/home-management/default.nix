{ config, pkgs, lib, ... }:
let
  cfg = config.my.system.home-management;
in {
  options.my.system.home-management = {
    assets = {
      enable = lib.mkEnableOption "Whether to enable asset-management.";
      host = lib.mkOption {
        type = lib.types.str;
        description = "Host address for asset-management server access.";
        default = "127.0.0.1";
      };
      port = lib.mkOption {
        type = lib.types.port;
        description = "Port for asset-management server.";
        default = 8000;
      };
    };
  };

  config = {
    services.homebox = lib.mkIf cfg.assets.enable {
      enable = true;
      settings = {
        HBOX_STORAGE_CONN_STRING = "file:///var/lib/homebox";
        HBOX_STORAGE_PREFIX_PATH = "data";
        HBOX_DATABASE_DRIVER = "sqlite3";
        HBOX_DATABASE_SQLITE_PATH = "/var/lib/homebox/data/homebox.db?_pragma=busy_timeout=999&_pragma=journal_mode=WAL&_fk=1";
        HBOX_OPTIONS_ALLOW_REGISTRATION = "false";
        # HBOX_OPTIONS_ALLOW_REGISTRATION = "true";
        HBOX_OPTIONS_CHECK_GITHUB_RELEASE = "false";
        HBOX_MODE = "production";

        HBOX_WEB_PORT = toString cfg.assets.port;
        HBOX_WEB_HOST = cfg.assets.host;
        HBOX_OPTIONS_TRUST_PROXY = "true";
      };
    };
  };
}
