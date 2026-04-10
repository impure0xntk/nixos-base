{ lib, nanogptParams, ... }:
let
in
{
  mistral-small-4 = [
    { model = "openai/mistralai/mistral-small-4-119b-2603"; params = nanogptParams; }
  ];
}
