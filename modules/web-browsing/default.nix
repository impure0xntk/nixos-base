{ config, lib, ... }:
let
  cfg = config.my.system.web-browsing;
in {
  options.my.system.web-browsing = {
    enable = lib.mkEnableOption "Whether to enable web-browsing daemon.";
    adguardHome = {
      enable = lib.mkEnableOption "Whether to enable AdGuard Home for ad blocking.";
      bindAddress = lib.mkOption {
        type = lib.types.str;
        description = "Bind address for AdGuard Home.";
        default = "127.0.0.1";
      };
      port = lib.mkOption {
        type = lib.types.port;
        description = "Port for AdGuard Home.";
        default = 3000;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    boot.enableContainers = true;
    containers.adguardhome = {
      autoStart = true;

      config = {config, pkgs, lib, ...}: {
        imports = [ ../core/minimal.nix ];
        system.stateVersion = config.system.nixos.release;

        services.journald.extraConfig = ''
          SystemMaxUse=100M
        '';

        services.adguardhome = {
          enable = cfg.adguardHome.enable;
          host = cfg.adguardHome.bindAddress;
          port = cfg.adguardHome.port;
          settings = {
            http = {
              # You can select any ip and port, just make sure to open firewalls where needed
              address = "${cfg.adguardHome.bindAddress}:${toString cfg.adguardHome.port}";
            };
            dns = {
              bind_hosts = [ cfg.adguardHome.bindAddress ];
              port = 53;
              upstream_dns = [
                "9.9.9.9"
              ];
            };
            filtering = {
              protection_enabled = true;
              filtering_enabled = true;

              parental_enabled = false;  # Parental control-based DNS requests filtering.
              safe_search = {
                enabled = false;  # Enforcing "Safe search" option for search engines, when possible.
              };
            };
            # The following notation uses map
            # to not have to manually create {enabled = true; url = "";} for every filter
            # This is, however, fully optional
            filters = map (url: { enabled = true; url = url; }) (import ./adh-filters.nix { inherit lib; });
          };
        };
      };
    };
  };
}
