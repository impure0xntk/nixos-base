{ config, pkgs, lib, ... }:
let
  cfg = config.my.system.home-management;
  package = pkgs.pure-unstable.homebox; # to use OIDC feature: 0.22+
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
      oidc = {
        enable = lib.mkEnableOption "Whether to enable OIDC integration";
        # name =
        provider = {
          issuerUrl = lib.mkOption {
            type = lib.types.str;
            description = "Issuer URL";
            example = "https://auth.example.com";
          };
          clientId = lib.mkOption {
            type = lib.types.str;
            description = "Client ID";
            example = "";
          };
          clientSecretFile = lib.mkOption {
            type = lib.types.str;
            description = "Client Secret File Path. Recommend to set secret store's path";
          };
        };
      };
    };
  };

  config = {
    services.homebox = lib.mkIf cfg.assets.enable {
      enable = true;
      inherit package;
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

        HBOX_OIDC_ENABLED = toString cfg.assets.oidc.enable;
        HBOX_OIDC_ISSUER_URL = cfg.assets.oidc.provider.issuerUrl;
        HBOX_OIDC_CLIENT_ID = cfg.assets.oidc.provider.clientId;
      };
    };
    systemd.services.homebox.serviceConfig.EnvironmentFile = lib.optionalString cfg.assets.oidc.enable cfg.assets.oidc.provider.clientSecretFile;
  };
}
