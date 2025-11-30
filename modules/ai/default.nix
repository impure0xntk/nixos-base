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
    chat = {
      enable = lib.mkEnableOption "Whether to enable Open-WebUI";
      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Host for the Open-WebUI server.";
      };
      port = lib.mkOption {
        type = lib.types.int;
        default = 1173;
        description = "Port for the Open-WebUI server.";
      };
      promptTemplate = lib.mkOption {
        type = lib.types.str;
        default = defaultPrompt;
        description = "Prompt template for the Open-WebUI server.";
      };
      providerBaseUrl = lib.mkOption {
        type = lib.types.str;
        default = "http://127.0.0.1:1173";
        description = "OpenAI API provider base url";
      };
      defaultModel = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Default model for the Open-WebUI server.";
      };
      webSearchBaseUrl = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Web Search(searxng) base url";
      };
      environments = lib.mkOption {
        type = lib.types.attrs;
        default = {};
        description = "Environments";
      };
      environmentFilePath = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to the environment file containing API keys for Open-WebUI.";
      };
    };
    vectorDatabase = {
      enable = lib.mkEnableOption "Whether to enable vector database";
      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Qdrant service host address";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 6333;
        description = "Qdrant service port number";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    boot.enableContainers = true;

    containers.ai-proxy = lib.mkIf cfg.proxy.enable {
      autoStart = true;

      bindMounts."/run/credentials/litellm.service/env" = lib.mkIf (cfg.proxy.environmentFilePath != null) {
        hostPath = cfg.proxy.environmentFilePath;
        isReadOnly = true;
      };

      config =
        {
          config,
          lib,
          ...
        }:
        {
          imports = [ ../core/minimal.nix ];
          system.stateVersion = config.system.nixos.release;

          services.journald.extraConfig = ''
            SystemMaxUse=100M
          '';

          services.litellm = {
            enable = true;
            package = pkgs.pure-unstable.litellm;
            settings = settingsAll;
            host = cfg.proxy.host;
            port = cfg.proxy.port;
            environmentFile = if (cfg.proxy.environmentFilePath == null)
              then null else "/run/credentials/litellm.service/env";

            environment = {
              ANONYMIZED_TELEMETRY = "False";
              DO_NOT_TRACK = "True";
              SCARF_NO_ANALYTICS = "True";
              DISABLE_ADMIN_UI = "True";
              NO_DOCS = "True";
            } // (lib.optionalAttrs (cfgProxy != "") {
              HTTPS_PROXY = cfgProxy;
            });

          };
        };
    };

    containers.ai-chat = lib.mkIf cfg.chat.enable {
      autoStart = true;

      bindMounts."/run/credentials/open-webui.service/env" = lib.mkIf (cfg.chat.environmentFilePath != null) {
        hostPath = cfg.chat.environmentFilePath;
        isReadOnly = true;
      };

      config =
        {
          config,
          lib,
          ...
        }:
        {
          imports = [ ../core/minimal.nix ];
          system.stateVersion = config.system.nixos.release;

          services.journald.extraConfig = ''
            SystemMaxUse=100M
          '';

          services.open-webui = {
            enable = true;
            package = pkgs.pure-unstable.open-webui;
            host = cfg.chat.host;
            port = cfg.chat.port;
            environmentFile = if (cfg.chat.environmentFilePath == null)
              then null else "/run/credentials/open-webui.service/env";

            environment = {
              ANONYMIZED_TELEMETRY = "False";
              DO_NOT_TRACK = "True";
              SCARF_NO_ANALYTICS = "True";

              WEBUI_AUTH = "False";

              DEFAULT_MODELS = cfg.chat.defaultModel or "";
              OPENAI_API_BASE_URL = cfg.chat.providerBaseUrl;

              ENABLE_WEB_SEARCH = if cfg.chat.webSearchBaseUrl != "" then "True" else "False";
              WEB_SEARCH_ENGINE = "searxng";
              SEARXNG_QUERY_URL = "${cfg.chat.webSearchBaseUrl}/search?q=<query>";
            } // (lib.optionalAttrs (cfgProxy != "") {
              https_proxy = cfgProxy;
            });

          };
        };
    };

    containers.ai-vector-database = lib.mkIf cfg.vectorDatabase.enable {
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
                host = cfg.vectorDatabase.host;
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
