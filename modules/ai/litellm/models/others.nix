{ lib, opencodeZenParams, nanogptParams, ... }:

{
  "minimax-m2.7"= [
    { model = "openrouter/minimax/minimax-m2.7:free"; }
  ];
  "laguna-s-2.1" = [
    { model = "openrouter/poolside/laguna-s-2.1:free"; }
  ];
  "north-mini-code" = [
    { model = "openrouter/cohere/north-mini-code:free"; }
  ];
  "ling-3.0-flash" = [
    { model = "openrouter/inclusionai/ling-3.0-flash:free"; }
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
  text-to-speech-playai-tts = [
    {
      model = "groq/playai-tts";
      params = {
      };
    }
  ];
}
