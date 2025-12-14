{ config, pkgs, lib, ... }:
let
  cfg = config.my.system.memo;
in {
  options.my.system.memo = {
    enable = lib.mkEnableOption "Whether to enable memo (Memos server).";
    host = lib.mkOption {
      type = lib.types.str;
      description = "Host address for Memos server access.";
      default = "127.0.0.1";
    };
    port = lib.mkOption {
      type = lib.types.port;
      description = "Port for Memos server.";
      default = 8080;
    };
    dataDir = lib.mkOption {
      type = lib.types.path;
      description = "Host path for Memos data directory.";
      default = "/var/lib/memos";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.memos = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];
      description = "Memos, a privacy-first, lightweight note-taking solution";
      serviceConfig = {
        Type = "simple";
        RestartSec = 60;
        LimitNOFILE = 65536;
        NoNewPrivileges = true;
        LockPersonality = true;
        RemoveIPC = true;
        ReadWritePaths = [
          cfg.dataDir
        ];
        DynamicUser = true;
        ProtectSystem = "strict";
        PrivateUsers = true;
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectHostname = true;
        ProtectClock = true;
        UMask = "0077";
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        ProtectProc = "invisible";
        RuntimeDirectory = "memos";
        StateDirectory = "memos";
        SystemCallFilter = [
          " " # This is needed to clear the SystemCallFilter existing definitions
          "~@reboot"
          "~@swap"
          "~@obsolete"
          "~@mount"
          "~@module"
          "~@debug"
          "~@cpu-emulation"
          "~@clock"
          "~@raw-io"
          "~@privileged"
          "~@resources"
        ];
        CapabilityBoundingSet = [
          " " # Reset all capabilities to an empty set
        ];
        RestrictAddressFamilies = [
          " " # This is needed to clear the RestrictAddressFamilies existing definitions
          "none" # Remove all addresses families
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
        ];
        DevicePolicy = "closed";
        ProtectKernelLogs = true;
        SystemCallArchitectures = "native";
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        ExecStart = lib.getExe pkgs.memos;
        EnvironmentFile = pkgs.writeText "memos-envfile" ''
          MEMOS_MODE=prod
          MEMOS_ADDR=${cfg.host}
          MEMOS_PORT=${toString cfg.port}
          MEMOS_DATA=${cfg.dataDir}
          MEMOS_DRIVER=sqlite
          MEMOS_INSTANCE_URL=http://${cfg.host}:${toString cfg.port}
        '';
      };
    };
  };
}
