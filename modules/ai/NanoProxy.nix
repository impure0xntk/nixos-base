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
    systemd.services.NanoProxy = {
      description = "NanoProxy";
      environment = {
        PROXY_HOST = cfg.host;
        PROXY_PORT = "8787";
        UPSTREAM_BASE_URL = "https://nano-gpt.com/api/subscription/v1"; # subscription models only
      };
      serviceConfig = {
        ExecStart = "${pkgs.NanoProxy}/bin/nanoproxy";
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
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
