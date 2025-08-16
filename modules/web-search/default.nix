{ config, lib, ... }:
let
  cfg = config.my.system.web-search;
in {
  options.my.system.web-search = {
    enable = lib.mkEnableOption "Whether to enable web-scraping daemon.";
    port = lib.mkOption {
      type = lib.types.port;
      description = "Port for web-scraping server.";
      default = 16060;
    };
  };

  config = lib.mkIf cfg.enable {
    boot.enableContainers = true;
    containers.searxng = {
      autoStart = true;

      config = {config, pkgs, lib, ...}: {
        imports = [ ../core/minimal.nix ];
        system.stateVersion = config.system.nixos.release;

        services.journald.extraConfig = ''
          SystemMaxUse=100M
        '';

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
              bind.address = "127.0.0.1";
              port = cfg.port;
              secret_key = "dummy";
            };
          };
        };
      };
    };
  };
}
