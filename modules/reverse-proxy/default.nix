{ config, lib, ... }:
let
  cfg = config.my.system.reverse-proxy;
  certDir = "/etc/ssl/caddy";
in {
  options.my.system.reverse-proxy = {
    enable = lib.mkEnableOption "";
    bindAddress = lib.mkOption {
      type = lib.types.str;
      description = "Bind address for Reverse Proxy server.";
      default = "127.0.0.1";
    };
    certFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      description = "Path to TLS certificate file for TLS.";
      default = null;
    };
    keyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      description = "Path to TLS key file for TLS.";
      default = null;
    };
    reloadCommand = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Command to reload the Reverse Proxy server configuration. This is useful to apply new TLS certificates after renewal.";
      # To load new TLS certificates after renewal with systemd-creds
      default = "machinectl shell reverse-proxy /run/current-system/sw/bin/systemctl restart caddy.service";
    };
    configFileCreateFunction = lib.mkOption {
      type = lib.types.functionTo (lib.types.functionTo lib.types.str); # Use currying to represent a function that takes two arguments
      description = "Function to create the Caddyfile configuration content. The function receives two arguments: the path to the TLS certificate file and the path to the TLS key file.";
      default = certPath: keyPath: "";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.enableContainers = true;
    containers.reverse-proxy = {
      autoStart = true;

      bindMounts = {
        "${certDir}/cert.pem" = lib.mkIf (cfg.certFile != null) {
          hostPath = cfg.certFile;
          isReadOnly = true;
        };
        "${certDir}/key.pem" = lib.mkIf (cfg.keyFile != null) {
          hostPath = cfg.keyFile;
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
        systemd.services.caddy.serviceConfig = {
          LoadCredential = [
            "cert.pem:${certDir}/cert.pem"
            "key.pem:${certDir}/key.pem"
          ];
        };

        services.caddy = {
          enable = cfg.enable;
          configFile = pkgs.writeText "Caddyfile" (cfg.configFileCreateFunction "/run/credentials/caddy.service/cert.pem" "/run/credentials/caddy.service/key.pem");
        };
      };
    };
  };
}
