# TODO: add deepseek official model
{ nanogptParams, ... }:
let
in
{
  "deepseek-v4-flash" = [
    { order = 1; model = "openai/deepseek/deepseek-v4-flash"; params = nanogptParams; }
    # In 2026/05/23 openrouter returns 429
    # { order = 2; model = "openrouter/deepseek/deepseek-v4-flash:free"; }
  ];
  "deepseek-v4-flash-think" = [
    { order = 1; model = "openai/deepseek/deepseek-v4-flash:thinking"; params = nanogptParams; }
    # In 2026/05/23 openrouter returns 429
    # { order = 2; model = "openrouter/deepseek/deepseek-v4-flash:free"; params = { extra_body = reasoning = { effort = "high"; }; }; }
  ];
  "deepseek-v4-pro" = [
    { model = "openai/deepseek/deepseek-v4-pro-cheaper"; params = nanogptParams; }
  ];
  "deepseek-v4-pro-think" = [
    { model = "openai/deepseek/deepseek-v4-pro-cheaper:thinking"; params = nanogptParams; }
  ];
}
