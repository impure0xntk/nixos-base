{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.system.ai;
  cfgProxy = config.my.system.networks.proxy;

  settingsDefault = {
    litellm_settings = {
      num_retries = 5;
      cache = true;
      cache_params = {
        type = "local";
        # type = "disk";
        # disk_cache_dir = "/tmp/litellm-cache";
      };
      drop_params = true;
    };
    model_list = cfg.proxy.model_list;
    router_settings = {
      base_delay = 3;
      max_delay = 15;
      jitter = true;
    };
  };
  settingsAll = lib.recursiveUpdate settingsDefault cfg.proxy.settings;
in
{
  options.my.system.ai = {
    enable = lib.mkEnableOption "Whether to enable AI features.";
    proxy = {
      enable = lib.mkEnableOption "Whether to enable proxy for AI services";
      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Host for the LiteLLM API server.";
      };
      port = lib.mkOption {
        type = lib.types.int;
        default = 1173;
        description = "Port for the LiteLLM API server.";
      };
      settings = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "LiteLLM settings. This outputs to yaml.";
      };
      model_list = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = [ ];
        description = "List of models to be enabled in LiteLLM.";
      };
      environmentFilePath = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to the environment file containing API keys for LiteLLM.";
      };
      presetModels = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = (import ./litellm/models {inherit lib;});
        description = "Preset models";
      };
    };
  };

  imports = [
    ./local.nix
    ./NanoProxy.nix
  ];

  config = lib.mkIf cfg.enable {
    # Litellm needs host environment: some models such as Github Copilot needs auth by hand
    services.litellm = {
      enable = cfg.proxy.enable;
      package = pkgs.pure-unstable.litellm;
      settings = settingsAll;
      host = cfg.proxy.host;
      port = cfg.proxy.port;
      environmentFile = cfg.proxy.environmentFilePath;

      environment = {
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
        SCARF_NO_ANALYTICS = "True";
        DISABLE_ADMIN_UI = "True";
        NO_DOCS = "True";
        HOME = config.systemd.services.litellm.serviceConfig.WorkingDirectory;

        # For GitHub Copilot
        GITHUB_COPILOT_TOKEN_DIR = "${config.services.litellm.stateDir}/github_copilot";
        # For NanoGPT tool calling. See ./NanoProxy.nix
        NANOGPT_API_BASE = "http://${cfg.proxy.host}:8787";
      } // (lib.optionalAttrs (cfgProxy != "") {
        HTTPS_PROXY = cfgProxy;
      });
    };
  };
}
