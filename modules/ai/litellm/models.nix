# Inspire: https://github.com/bowmanjd/nix-config/raw/ec086d5cb5be0fc4bc39b12e9f1d132c60b738d5/home-manager/llm/litellm-config.yaml

{ lib, ... }:
let
  wildcard = modelName: rec {
    model_name = "${modelName}/*";
    litellm_params = {
      model = model_name;
    };
  };
  wildcardWithApiKey = modelName: api_key_name: rec {
    model_name = "${modelName}/*";
    litellm_params = {
      model = model_name;
      api_key = "os.environ/${api_key_name}";
    };
  };
in [
  (wildcard "chatgpt")
  (wildcardWithApiKey "openrouter" "OPENROUTER_API_KEY")
  rec {
    model_name = "github_copilot/*";
    litellm_params = {
      model = model_name;
      extra_headers = {
        "editor-version" = "vscode/1.103.2";
        "editor-plugin-version" = "copilot/1.155.0";
        "Copilot-Integration-Id" = "vscode-chat";
        "user-agent" = "GithubCopilot/1.155.0";
      };
    };
  }
]
