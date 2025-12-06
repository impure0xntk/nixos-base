{ config, pkgs, lib, ... }:
let
  cfg = config.my.system.workflow;
in {
  options.my.system.workflow = {
    enable = lib.mkEnableOption "Whether to enable workflow daemon.";
    host = lib.mkOption {
      type = lib.types.str;
      description = "Host for workflow server.";
      default = "127.0.0.1";
    };
    port = lib.mkOption {
      type = lib.types.port;
      description = "Port for workflow server.";
      default = 5678;
    };
  };

  config = lib.mkIf cfg.enable {
    boot.enableContainers = true;
    containers.workflow = {
      autoStart = true;

      config = {config, pkgs, lib, ...}: {
        imports = [ ../core/minimal.nix ];
        system.stateVersion = config.system.nixos.release;

        services.journald.extraConfig = ''
          SystemMaxUse=100M
        '';

        nixpkgs.config.allowUnfree = true;
        services.n8n = {
          enable = true;
          environment = rec {
            N8N_HOST = cfg.host;
            N8N_PORT = toString cfg.port;
            N8N_PROTOCOL = "http";
            N8N_RUNNERS_ENABLED = "true";
            NODE_FUNCTION_ALLOW_EXTERNAL = "true";
            WEBHOOK_URL = "${N8N_PROTOCOL}://${N8N_HOST}:${N8N_PORT}";
            NODE_ENV = "production";
          };
        };
      };
    };
  };
}
