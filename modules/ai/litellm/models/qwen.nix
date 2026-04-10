{ lib, nanogptParams, ... }:
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
    "qwen3.5-think" = [
      { model = "openai/qwen/qwen3.5-397b-a17b-thinking"; params = nanogptParams; }
    ];
    "qwen3.5" = [
      { model = "openai/qwen/qwen3.5-397b-a17b"; params = nanogptParams; }
    ];
  };
in models // {
  # "qwen3.5-nothink" = noThink models."qwen3.5";
}
