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
  in "${pkgs.writeShellScriptBin "add-custom-guardrail-${name}" ''
      set -x
      unlink ${name} || true
      ln -s ${path}
    ''}/bin/add-custom-guardrail-${name}"
  );

  leanCtxConfigDir = pkgs.runCommand "lean-ctx-config" {} ''
    mkdir -p $out
    cat > $out/config.toml <<'EOF'
    proxy_loopback_open = true
    EOF
  '';

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
        default = pkgs.my.lean-ctx;
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
    systemd.services.litellm.serviceConfig.ExecStartPre = addCustomGuardrailScript [
      "${pkgs.my.litellm-guardrail-lean-ctx}/lib/python3.13/site-packages/litellm_guardrail_lean_ctx"
    ];
    systemd.services.lean-ctx = {
      description = "lean-ctx compression proxy";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      environment = {
        # LEAN_CTX_PROXY_BIND_HOST = cfg.host; # disable: loopback only
        LEAN_CTX_CONFIG_DIR = leanCtxConfigDir;
        LEAN_CTX_NO_UPDATE_CHECK = "1";
        LEAN_CTX_PROXY_PORT = toString cfg.compression.lean-ctx.port;
        LEAN_CTX_COMPRESSION = "standard";
        LEAN_CTX_PROXY_HISTORY_MODE = "off"; # delegate to litellm
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
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
