{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.my.system.ai.proxy;
in {
  options.my.system.ai.proxy.compression = {
    enable = lib.mkEnableOption "Whether to enable compression service for LLM";
    port = lib.mkOption {
      type = lib.types.int;
      default = 8787;
      description = "Port for the compression server.";
    };
  };
  config = lib.mkIf cfg.compression.enable {
    # https://docs.litellm.ai/docs/proxy/headroom
    my.system.ai.proxy.settings.guardrails = [{
      guardrail_name = "headroom-compression";
      litellm_params = {
        guardrail = "headroom";
        mode = "pre_call";
        api_base = "http://${cfg.host}:${toString cfg.compression.port}";
        default_on = true;
      };
    }];

    systemd.services.headroom-ai = {
      description = "headroom-ai";
      after = [ "network-online.target" ];
      environment = {
        HEADROOM_COMPRESS_USER_MESSAGES = "true"; # To compress tool_call result
        HEADROOM_MIN_TOKENS = "200"; # 500 by default

        HEADROOM_COMPRESS_ALLOW_REMOTE = "true";
        HEADROOM_TELEMETRY = "off";
        HF_HOME = "/tmp/hf"; # For onnx model fetch
      };
      serviceConfig = {
        ExecStart = lib.concatStringsSep " " [
          "${pkgs.my.headroom-ai.code-proxy}/bin/headroom proxy"
          "--host" cfg.host
          "--port" (toString cfg.compression.port)
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
