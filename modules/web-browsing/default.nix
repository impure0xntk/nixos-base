{ config, lib, ... }:
let
  cfg = config.my.system.web-browsing;
  certDir = "/etc/ssl/blocky";
in {
  options.my.system.web-browsing = {
    enable = lib.mkEnableOption "Whether to enable web-browsing daemon.";
    dns = {
      enable = lib.mkEnableOption "Whether to enable DNS server for ad-blocking.";
      bindAddress = lib.mkOption {
        type = lib.types.str;
        description = "Bind address for DNS server.";
        default = "127.0.0.1";
      };
      certFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        description = "Path to TLS certificate file for DNS over TLS.";
        default = null;
      };
      keyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        description = "Path to TLS key file for DNS over TLS.";
        default = null;
      };
      reloadCommand = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = "Command to reload the DNS server configuration. This is useful to apply new TLS certificates after renewal.";
        # To load new TLS certificates after renewal with systemd-creds
        default = "machinectl shell dns-server /run/current-system/sw/bin/systemctl restart blocky.service";
      };
    };
    blocklists = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            host = lib.mkOption {
              type = lib.types.str;
              description = "Host to block.";
            };
            category = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "Categories for the blocked host.";
              default = [ ];
            };
          };
        }
      );
      default = [];
      example = [
        {
          host = "localhost";
          category = [ "default" "strict" ];
        }
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    boot.enableContainers = true;
    containers.dns-server = {
      autoStart = true;

      bindMounts = {
        "${certDir}/cert.pem" = lib.mkIf (cfg.dns.certFile != null) {
          hostPath = cfg.dns.certFile;
          isReadOnly = true;
        };
        "${certDir}/key.pem" = lib.mkIf (cfg.dns.keyFile != null) {
          hostPath = cfg.dns.keyFile;
          isReadOnly = true;
        };
      };


      config = {config, pkgs, lib, ...}: {
        imports = [ ../core/minimal.nix ];
        system.stateVersion = config.system.nixos.release;

        services.journald.extraConfig = ''
          SystemMaxUse=100M
        '';

        # Must use systemd-creds to load TLS credentials because of systemd sandboxing
        # Similar: https://mynixos.com/nixpkgs/option/services.godns.settings
        systemd.services.blocky.serviceConfig = {
          LoadCredential = [
            "cert.pem:${certDir}/cert.pem"
            "key.pem:${certDir}/key.pem"
          ];
        };

        services.blocky = {
          enable = cfg.dns.enable;
          settings = {
            certFile = lib.optionalString (cfg.dns.certFile != null) "/run/credentials/blocky.service/cert.pem";
            keyFile = lib.optionalString (cfg.dns.keyFile != null) "/run/credentials/blocky.service/key.pem";
            log = {
              level = "debug";
              privacy = true;
            };
            ports = {
              dns = 53;
              http = 4000;
              https = 443;
              tls = 853;
            };
            upstreams = {
              strategy = "strict";
              init.strategy = "fast";
              groups = {
                default = [
                  "https://dns11.quad9.net/dns-query" # Quad9 DoH Secured w/ECS: Malware blocking, DNSSEC Validation, ECS enabled
                ];
              };
            };
            blocking = {
              loading.strategy = "fast";
              denylists = {
                general = [
                  "https://sebsauvage.net/hosts/hosts"
                  "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts" # Unified + fakenews + gambling
                  "https://raw.githubusercontent.com/sjhgvr/oisd/main/domainswild2_big.txt"
                  "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/hosts/ultimate.txt"
                ];
                ads = [
                  "https://blocklistproject.github.io/Lists/ads.txt"
                  # Youtube
                  "https://raw.githubusercontent.com/kboghdady/youTube_ads_4_pi-hole/master/youtubelist.txt"
                  # Regional Ads (Japan)
                  "https://warui.intaa.net/adhosts/hosts.txt"
                  "https://raw.githubusercontent.com/lawnn/adaway-hosts/refs/heads/master/hosts.txt"
                  "https://raw.githubusercontent.com/PepperCat-YamanekoVillage/LINE-Ad-Block/refs/heads/main/list.txt" # LINE Ads
                ];
                tracking = [
                  "https://blocklistproject.github.io/Lists/tracking.txt"
                  "https://github.com/KnightmareVIIVIIXC/AIO-Firebog-Blocklists/raw/main/hostslists/firebogtrack.txt"
                ];
                malicious = [
                  "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/hosts/tif.txt"
                  "https://s3.amazonaws.com/lists.disconnect.me/simple_malvertising.txt"
                  "https://github.com/KnightmareVIIVIIXC/AIO-Firebog-Blocklists/raw/main/hostslists/firebogmal.txt"
                ];
                annoyance = [
                  "https://github.com/KnightmareVIIVIIXC/AIO-Firebog-Blocklists/raw/main/hostslists/firebogsus.txt"
                  "https://raw.githubusercontent.com/bigdargon/hostsVN/refs/heads/master/hosts"
                  "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/gambling.txt"
                ];
                misc = [
                  "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/doh-vpn-proxy-bypass.txt"
                  "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/dyndns.txt"
                  "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/spam-tlds-onlydomains.txt"
                ];
                strict = [
                  "https://raw.githubusercontent.com/sjhgvr/oisd/main/domainswild2_nsfw.txt"
                  "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/nsfw.txt"
                  "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn-social-only/hosts" # porn + social
                ];
              };
              clientGroupsBlock = {
                default = [
                  "general"
                  "ads"
                  "tracking"
                  "malicious"
                  "annoyance"
                  "misc"
                ]; } // (lib.optionalAttrs (lib.length cfg.blocklists > 0) (
                lib.listToAttrs (map (item: lib.nameValuePair item.host item.category) cfg.blocklists)
              ));
            };
            queryLog.type = "console";
          };
        };
      };
    };
  };
}
