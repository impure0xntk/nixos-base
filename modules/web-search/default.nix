{ config, lib, ... }:
let
  cfg = config.my.system.web-search;
in {
  options.my.system.web-search = {
    enable = lib.mkEnableOption "Whether to enable web-scraping daemon.";
    host = lib.mkOption {
      type = lib.types.str;
      description = "Host for web-scraping server.";
      default = "127.0.0.1";
    };
    port = lib.mkOption {
      type = lib.types.port;
      description = "Port for web-scraping server.";
      default = 16060;
    };
  };

  config = lib.mkIf cfg.enable {
    services.searx = {
      enable = true;
      settings = {
        general = {
          debug = false;
          donation_url = false;
          contact_url = false;
          privacypolicy_url = false;
          enable_metrics = false;
        };
        search = {
          formats = [
            "json"
          ];
        };
        server = {
          bind_address = cfg.host; # Perhaps must be set except localhost
          port = cfg.port;
          secret_key = "dummy";
        };
      };
    };
  };
}
