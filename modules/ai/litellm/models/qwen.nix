{ config, lib, ... }:
let
  noThink =
    models:
    (lib.forEach models (info: {
      model = info.model;
      params = info.params // {
        extra_body.reasoning.exclude = true;
      };
    }));
  models = {
    qwen3-think = [
      {
        model = "groq/qwen/qwen3-32b"; # primary
      }
    ];
    qwen3-coder = [
      {
        model = "openrouter/qwen/qwen3-coder:free";
      }
    ];
    # "qwen3.5-think" = [
    #   {
    #     model = "ollama/qwen3.5:9b";
    #     params = {
    #       api_url = "http://localhost:1143"; # TODO: parameterize
    #     };
    #   }
    # ];
  };
in models // {
  qwen3 = noThink models.qwen3-think;
  # "qwen3.5" = noThink models."qwen3.5-think";
}
