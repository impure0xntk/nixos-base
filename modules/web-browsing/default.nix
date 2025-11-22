{ config, lib, ... }:
let
  cfg = config.my.system.web-browsing;
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
    };
  };

  config = lib.mkIf cfg.enable {
    boot.enableContainers = true;
    containers.dns-server = {
      autoStart = true;

      config = {config, pkgs, lib, ...}: {
        imports = [ ../core/minimal.nix ];
        system.stateVersion = config.system.nixos.release;

        services.journald.extraConfig = ''
          SystemMaxUse=100M
        '';

        services.blocky = {
          enable = cfg.dns.enable;
          settings = {
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
                  "tcp-tls:dns.quad9.net"
                ];
              };
            };
            blocking = {
              loading.strategy = "failOnError";
              denylists = {
                general = [
                  "https://sebsauvage.net/hosts/hosts" # Includes Steven Black's Unified Hosts list
                  "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn-social-only/hosts" # fakenews + gambling + porn + social
                  "https://big.oisd.nl/domainswild"
                  "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/hosts/ultimate.txt"
                ];
                ads = [
                  "https://blocklistproject.github.io/Lists/ads.txt"
                  "https://v.firebog.net/hosts/Admiral.txt"
                  # Regional (Japan)
                  "https://warui.intaa.net/adhosts/hosts.txt"
                  "https://raw.githubusercontent.com/lawnn/adaway-hosts/refs/heads/master/hosts.txt"
                  "https://raw.githubusercontent.com/PepperCat-YamanekoVillage/LINE-Ad-Block/refs/heads/main/list.txt" # LINE Ads
                ];
                tracking = [
                  "https://blocklistproject.github.io/Lists/tracking.txt"
                  "https://v.firebog.net/hosts/Prigent-Ads.txt"
                ];
                malicious = [
                  "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/hosts/tif.txt"
                  "https://s3.amazonaws.com/lists.disconnect.me/simple_malvertising.txt"
                  "https://v.firebog.net/hosts/Prigent-Malware.txt"
                  "https://v.firebog.net/hosts/Prigent-Phishing.txt"
                  "https://v.firebog.net/hosts/Prigent-Crypto.txt"
                ];
                annoyance = [
                  "https://nsfw.oisd.nl/domainswild"
                  "https://v.firebog.net/hosts/Prigent-Adult.txt"
                  "https://raw.githubusercontent.com/bigdargon/hostsVN/refs/heads/master/hosts"
                  "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/nsfw.txt"
                  "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/gambling.txt"
                ];
                misc = [
                  "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/doh-vpn-proxy-bypass.txt"
                  "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/dyndns.txt"
                  "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/spam-tlds-onlydomains.txt"
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
                ];
              };
            };
            queryLog.type = "console";
          };
        };
      };
    };
  };
}
