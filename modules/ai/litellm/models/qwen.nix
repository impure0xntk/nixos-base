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
    "qwen3-coder" = [
      { model = "openrouter/qwen/qwen3-coder:free"; }
    ];
    "qwen3.5-think" = [
      { model = "openai/qwen/qwen3.5-397b-a17b-thinking"; params = nanogptParams; }
    ];
    "qwen3.5" = [
      { model = "openai/qwen/qwen3.5-397b-a17b"; params = nanogptParams; }
    ];
    # For role play
    "qwen3.5-bluestar" = [
      { model = "openai/Qwen3.5-27B-BlueStar-Derestricted"; params = nanogptParams; }
    ];
    "qwen3.5-bluestar-light" = [
      { model = "openai/Qwen3.5-27B-BlueStar-Derestricted-Lite"; params = nanogptParams; }
    ];
    "qwen3.5-bluestar-v2" = [
      { model = "openai/Qwen3.5-27B-BlueStar-v2-Derestricted"; params = nanogptParams; }
    ];
    "qwen3.5-bluestar-v2-light" = [
      { model = "openai/Qwen3.5-27B-BlueStar-v2-Derestricted-Lite"; params = nanogptParams; }
    ];
  };
in models // {
  # "qwen3.5-nothink" = noThink models."qwen3.5";
}
