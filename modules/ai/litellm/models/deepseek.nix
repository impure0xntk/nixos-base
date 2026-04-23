# TODO: add deepseek official model
{ nanogptParams, ... }:
let
in
{
  "deepseek-v3.2" = [
    { model = "openai/deepseek/deepseek-v3.2"; params = nanogptParams; }
  ];
  "deepseek-v3.2-think" = [
    { model = "openai/deepseek/deepseek-v3.2"; params = nanogptParams; }
  ];
  "deepseek-v4-flash" = [
    { model = "openai/deepseek/deepseek-v4-flash"; params = nanogptParams; }
  ];
  "deepseek-v4-flash-think" = [
    { model = "openai/deepseek/deepseek-v4-flash:thinking"; params = nanogptParams; }
  ];
}
