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
}
