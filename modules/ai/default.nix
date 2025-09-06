{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.system.ai;
in
{
  options.my.system.ai = {
    enable = lib.mkEnableOption "Whether to enable AI features.";
    vectorDatabase = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "Whether to enable vector database";
          port = lib.mkOption {
            type = lib.types.port;
            default = 6333;
            description = "Qdrant service port number";
          };
        };
      };
      default = {};
      description = "Vector database configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    # Vector database config.
    boot.enableContainers = true;
    containers.qdrant = lib.mkIf cfg.vectorDatabase.enable {
      autoStart = true;

      config =
        {
          config,
          pkgs,
          lib,
          ...
        }:
        {
          imports = [ ../core/minimal.nix ];
          system.stateVersion = config.system.nixos.release;

          services.journald.extraConfig = ''
            SystemMaxUse=100M
          '';

          services.qdrant = lib.mkIf cfg.vectorDatabase.enable {
            enable = true;
            settings = {
              service = {
                http_port = cfg.vectorDatabase.port;
              };
              hsnw_index = {
                on_disk = true;
              };
              storage = {
                snapshots_path = "/var/lib/qdrant/snapshots";
                storage_path = "/var/lib/qdrant/storage";
              };
              telemetry_disabled = true;
            };
          };
          systemd.services.qdrant.serviceConfig.ExecStartPre = pkgs.writeShellScript "qdrant-init.sh" ''
            mkdir -p /var/lib/qdrant
          '';
        };
    };
  };
}
