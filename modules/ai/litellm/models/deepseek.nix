# TODO: add deepseek official model
{ ... }:
let
in
{
  "deepseek-v3.2" = [
    { model = "nanogpt/deepseek/deepseek-v3.2"; }
  ];
  "deepseek-v3.2-think" = [
    { model = "nanogpt/deepseek/deepseek-v3.2"; }
  ];
}
