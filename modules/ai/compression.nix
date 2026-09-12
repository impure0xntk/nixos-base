{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.my.system.ai.proxy;

  addCustomGuardrailScript = paths: lib.forEach paths (path:
  let name = baseNameOf path;
  in pkgs.writeShellScript "add-custom-guardrail-${name}" ''
      set -x
      unlink ${name} || true
      ln -s ${path}
    ''
  );

  hardening = {
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
in
{
  options.my.system.ai.proxy.compression = {
    enable = lib.mkEnableOption "Whether to enable compression service for LLM";
    headroom = {
      enable = lib.mkEnableOption "Whether to enable headroom service for LLM";
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.my.headroom-ai.code-proxy;
        description = "Package to use for headroom service.";
      };
      port = lib.mkOption {
        type = lib.types.int;
        default = 8787;
        description = "Headroom port for compression service.";
      };
    };
    lean-ctx = {
      enable = lib.mkEnableOption "Whether to enable lean context service for LLM";
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.lean-ctx;
        description = "The lean-ctx package providing the proxy binary.";
      };
      port = lib.mkOption {
        type = lib.types.int;
        default = 8788;
        description = "Lean context port for compression service.";
      };
    };
  };

  config = lib.mkIf cfg.compression.enable {
    # https://docs.litellm.ai/docs/proxy/headroom
    my.system.ai.proxy.settings.guardrails = [
      {
        # 1st, lean-ctx
        # https://leanctx.com/docs/concepts/proxy/
        guardrail_name = "lean-ctx";
        litellm_params = {
          guardrail = "litellm_guardrail_lean_ctx.LeanCTXGuardrail";
          mode = "pre_call";
          # api_base = "http://${cfg.host}:${toString cfg.compression.lean-ctx.port}";
          api_base = "http://127.0.0.1:${toString cfg.compression.lean-ctx.port}"; # loopback only
          default_on = cfg.compression.lean-ctx.enable;
        };
      }
      {
        # 2nd, headroom
        guardrail_name = "headroom-compression";
        litellm_params = {
          guardrail = "headroom";
          mode = "pre_call";
          api_base = "http://${cfg.host}:${toString cfg.compression.headroom.port}";
          default_on = cfg.compression.headroom.enable;
        };
      }
    ];

    systemd.services.headroom-ai = {
      enable = cfg.compression.headroom.enable;
      description = "headroom-ai";
      after = [ "network-online.target" ];
      environment = {
        HEADROOM_COMPRESS_USER_MESSAGES = "true"; # To compress tool_call result
        HEADROOM_MIN_TOKENS = "200"; # 500 by default

        HEADROOM_COMPRESS_ALLOW_REMOTE = "true";
        HEADROOM_TELEMETRY = "off";
        HF_HOME = "/tmp/hf"; # For onnx model fetch
      };
      serviceConfig = hardening // {
        ExecStart = lib.concatStringsSep " " [
          "${cfg.compression.headroom.package}/bin/headroom"
          "proxy"
          "--host" cfg.host
          "--port" (toString cfg.compression.headroom.port)
        ];
        Restart = "on-failure";
        RestartSec = 5;
        StandardOutput = "journal";
        StandardError = "journal";
      };
      wantedBy = [ "multi-user.target" ];
    };

    # https://docs.litellm.ai/docs/proxy/guardrails/custom_guardrail
    systemd.services.litellm.serviceConfig.ExecStartPre = (addCustomGuardrailScript [
      "${pkgs.my.litellm-guardrail-lean-ctx}/lib/python3.13/site-packages/litellm_guardrail_lean_ctx"
    ]) ++ [
      (pkgs.writeShellScript "setup-directories" ''
        mkdir -p share state
      '')
    ];
    systemd.services.lean-ctx = let
      leanCtxConfigPath = lib.my.toToml { # https://leanctx.com/docs/configuration/
        # By default via `lean-ctx proxy enable`
        proxy_enabled = true;
        permission_inheritance = "on";
        minimal_overhead = true;
        structure_first = true;
        # journal_enabled = true;
        auto_capture = true;

        # Custom
        compression_level = "standard";
        checkpoint_interval = 0;
        path_jail = false;
        update_check_disabled = true;
        crush_verbatim_json = true;

        journal_enabled = true;
        debug_log = true;

        max_disk_mb = 512;
        max_staleness_days = 1;

        proxy_bind_host = "127.0.0.1"; # Loopback only to enable no auth
        proxy_port = cfg.compression.lean-ctx.port;
        proxy_loopback_open = true; # No auth: loopback only

        proxy = {
          history_mode = "off"; # delegate to litellm
        };
      };
    in {
      description = "lean-ctx compression proxy";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      environment = {
        LEAN_CTX_CONFIG_DIR = pkgs.runCommand "lean-ctx-config" {} ''
          mkdir -p $out
          ln -s ${leanCtxConfigPath} $out/config.toml
        '';
        LEAN_CTX_DATA_DIR = "/var/lib/lean-ctx/share";
        LEAN_CTX_STATE_DIR = "/var/lib/lean-ctx/state";
        LEAN_CTX_CACHE_DIR = "/var/cache/lean-ctx";
      };
      serviceConfig = hardening // {
        ExecStart = lib.concatStringsSep " " [
          "${cfg.compression.lean-ctx.package}/bin/lean-ctx"
          "proxy"
          "start"
        ];
        Restart = "on-failure";
        RestartSec = 5;
        StandardOutput = "journal";
        StandardError = "journal";

        WorkingDirectory = "/run/lean-ctx";
        RuntimeDirectory = "lean-ctx";
        StateDirectory = "lean-ctx";
        CacheDirectory = "lean-ctx";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
