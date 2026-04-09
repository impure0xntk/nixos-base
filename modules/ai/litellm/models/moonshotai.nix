{ lib, opencodeZenParams, ... }:
let
in
{
  kimi-k2 = [
    {
      model = "groq/moonshotai/kimi-k2-instruct-0905"; # primary
      params = { # additional params are unsupported
      };
    }
  ];
}
