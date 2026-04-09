{ lib, ... }:
let
in
{
  "llama-3.3" = [
    {
      model = "openrouter/meta-llama/llama-3.3-70b-instruct:free";
    }
  ];
  llama-4-maverick = [
    {
      model = "groq/meta-llama/llama-4-maverick-17b-128e-instruct"; # primary
      params = {
        # additional params are unsupported
      };
    }
  ];
  llama-4-scout = [
    {
      model = "groq/meta-llama/llama-4-scout-17b-16e-instruct"; # primary
      params = {
        # additional params are unsupported
      };
    }
  ];
}
