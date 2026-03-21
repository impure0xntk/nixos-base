{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.system.ai;
  cfgProxy = config.my.system.networks.proxy;

  defaultPrompt = ''
    ### Task:
    Analyze the chat history to determine the necessity of generating search queries, in the given language. By default, **prioritize generating 1-3 broad and relevant search queries** unless it is absolutely certain that no additional information is required. The aim is to retrieve comprehensive, updated, and valuable information even with minimal uncertainty. If no search is unequivocally needed, return an empty list.

    ### Guidelines:
    - クエリは必ず **日本語** にしてください
    - Respond **EXCLUSIVELY** with a JSON object. Any form of extra commentary, explanation, or additional text is strictly prohibited.
    - When generating search queries, respond in the format: { "queries": ["クエリ1", "クエリ2"] }, ensuring each query is distinct, concise, and relevant to the topic.
    - If and only if it is entirely certain that no useful results can be retrieved by a search, return: { "queries": [] }.
    - Err on the side of suggesting search queries if there is **any chance** they might provide useful or updated information.
    - Be concise and focused on composing high-quality search queries, avoiding unnecessary elaboration, commentary, or assumptions.
    - Today's date is: {{CURRENT_DATE}}.
    - Always prioritize providing actionable and broad queries that maximize informational coverage.

    ### Output:
    Strictly return in JSON format:
    {
      "queries": ["クエリ1", "クエリ2"]
    }

    ### Chat History:
    <chat_history>
    {{MESSAGES:END:6}}
    </chat_history>
  '';

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

  config = lib.mkIf cfg.enable {
    # Litellm needs host environment: some models such as Github Copilot needs auth by hand
    services.litellm = {
      enable = true;
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

        # For GitHub Copilot
        GITHUB_COPILOT_TOKEN_DIR = "${config.services.litellm.stateDir}/github_copilot";
      } // (lib.optionalAttrs (cfgProxy != "") {
        HTTPS_PROXY = cfgProxy;
      });

    };
  };
}
