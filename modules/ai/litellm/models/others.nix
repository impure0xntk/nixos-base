{ lib, opencodeZenParams, nanogptParams, ... }:

{
  "laguna-m.1" = [
    { model = "openrouter/poolside/laguna-m.1:free"; }
  ];
  "laguna-xs-2.1" = [
    { model = "openrouter/poolside/laguna-xs-2.1:free"; }
  ];
  "north-mini-code" = [
    { model = "openrouter/cohere/north-mini-code:free"; }
  ];
  "nemotron-3-super" = [
    { model = "openrouter/nvidia/nemotron-3-super-120b-a12b:free"; }
  ];
  "nemotron-3-ultra" = [
    { model = "openrouter/nvidia/nemotron-3-ultra-550b-a55b:free"; }
  ];
  "nemotron-embed" = [
    { model = "openrouter/nvidia/llama-nemotron-embed-vl-1b-v2:free"; }
  ];
  "hy3" = [
    { model = "openrouter/tencent/hy3:free"; }
  ];
  "minimax-m2.5" = [
    {
      model = "openai/minimax/minimax-m2.5";
      params = {
        order = 1;
      } // nanogptParams;
    }
    {
      model = "openrouter/minimax/minimax-m2.5:free";
      params = {
        order = 2;
      };
    }
  ];
  "minimax-m2.7" = [
    { model = "openai/minimax/minimax-m2.7"; params = nanogptParams; }
  ];
  text-to-speech-playai-tts = [
    {
      model = "groq/playai-tts";
      params = {
      };
    }
  ];
}
