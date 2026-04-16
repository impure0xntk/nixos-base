{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.my.system.ai.proxy;
in {
  config = lib.mkIf cfg.enable {
    systemd.services.headroom-ai = {
      description = "headroom-ai";
      after = [ "network-online.target" ];
      environment = {
        HEADROOM_SAVINGS_PATH  = "/tmp/proxy_saving.json";
      };
      serviceConfig = {
        ExecStart = lib.concatStringsSep " " [
          "${pkgs.headroom-ai}/bin/headroom" "proxy"
          "--host" cfg.host
          "--port" "${toString cfg.compression.port}"
          "--log-file" "/tmp/headroom-log.jsonl"
          "--no-rate-limit"
          "--no-telemetry"
          "--openai-api-url" "http://${cfg.host}:${toString cfg.port}"
        ];
        Restart = "on-failure";
        RestartSec = 5;
        StandardOutput = "journal";
        StandardError = "journal";

        # Hardened
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
          # "~@raw-io"
          "~@privileged"
          # "~@resources"
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
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
