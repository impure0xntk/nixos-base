# TODO: add deepseek official model
{ ... }:
let
in
{
  "deepseek-v3.2" = [
    { model = "nano-gpt/deepseek/deepseek-v3.2"; }
  ];
  "deepseek-v3.2-think" = [
    { model = "nano-gpt/deepseek/deepseek-v3.2"; }
  ];
}
