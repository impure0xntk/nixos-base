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
    "qwen3.5" = [
      { model = "nanogpt/qwen/qwen3.5-397b-a17b-thinking"; }
    ];
  };
in models // {
  "qwen3.5-nothink" = noThink models."qwen3.5";
}
