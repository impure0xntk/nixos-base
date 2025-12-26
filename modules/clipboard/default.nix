{ config, pkgs, lib, ... }:
let
  cfg = config.my.system.clipboard;
in {
  options.my.system.clipboard = {
    enable = lib.mkEnableOption "Whether to enable clipboard.";
    host = lib.mkOption {
      type = lib.types.str;
      description = "Host address for clipboard server access.";
      default = "127.0.0.1";
    };
    port = lib.mkOption {
      type = lib.types.port;
      description = "Port for clipboard server.";
      default = 8080;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.clipcascade-server = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];
      description = "${pkgs.clipcascade-server.meta.description}";
      serviceConfig = {
        Type = "simple";
        RestartSec = 60;
        LimitNOFILE = 65536;
        NoNewPrivileges = true;
        LockPersonality = true;
        RemoveIPC = true;
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
        ReadWritePaths = [
          "/run/clipcascade-server"
        ];
        WorkingDirectory = "/run/clipcascade-server";
        RuntimeDirectory = "clipcascade-server";
        StateDirectory = "clipcascade-server";
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
        ExecStart = lib.getExe pkgs.clipcascade-server;
        # CC_ADDRESS is only be able to use with custom ClipCascade build: patch required.
        EnvironmentFile = pkgs.writeText "clipcascade-server-envfile" ''
          CC_ADDRESS=${cfg.host}
          CC_PORT=${toString cfg.port}
          CC_MAX_USER_ACCOUNTS=1
        '';
      };
    };
  };
}
