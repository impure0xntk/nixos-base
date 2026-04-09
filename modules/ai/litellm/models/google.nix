# TODO: add gemini api
{ lib, ... }:
let
in
{
  "gemini-2.5-pro" = [
    {
      model = "gemini/gemini-2.5-pro";
    }
  ];
  "gemini-2.5-flash" = [
    {
      model = "gemini/gemini-2.5-flash";
      params = {
        fallbacks = [
          "gemini-2.5-flash-lite"
        ];
      };
    }
  ];
  "gemini-2.5-flash-lite" = [
    {
      model = "gemini/gemini-2.5-flash-lite";
    }
  ];
  gemini-3-flash = [
    {
      model = "gemini/gemini-3-flash-preview";
    }
  ];
  "gemini-3.1-flash-lite" = [
    {
      model = "gemini/gemini-3.1-flash-lite-preview";
    }
  ];
  gemma-4 = [
    {
      model = "gemini/gemma-4-31b-it";
      params = {
        order = 1;
      };
    }
    {
      model = "openrouter/google/gemma-4-31b-it:free";
      params = {
        order = 2;
      };
    }
  ];
}
