# TODO: add deepseek official model
{ nanogptParams, ... }:
let
in
{
  "deepseek-v4-flash" = [
    { model = "openai/deepseek/deepseek-v4-flash"; params = nanogptParams; }
  ];
  "deepseek-v4-flash-think" = [
    { model = "openai/deepseek/deepseek-v4-flash:thinking"; params = nanogptParams; }
  ];
  "deepseek-v4-pro" = [
    { model = "openai/deepseek/deepseek-v4-pro-cheaper"; params = nanogptParams; }
  ];
  "deepseek-v4-pro-think" = [
    { model = "openai/deepseek/deepseek-v4-pro-cheaper:thinking"; params = nanogptParams; }
  ];
}
