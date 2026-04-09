{ lib, ... }:
let
  noThink =
    models:
    (lib.forEach models (info: {
      model = info.model;
      params = (info.params or {}) // {
        extra_body.reasoning.exclude = true;
      };
    }));
  models = {
    qwen3 = [
      {
        model = "groq/qwen/qwen3-32b"; # primary
      }
    ];
    qwen3-coder = [
      {
        model = "openrouter/qwen/qwen3-coder:free";
      }
    ];
  };
in models // {
  qwen3-nothink = noThink models.qwen3;
}
