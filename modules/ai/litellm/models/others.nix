{ lib, opencodeZenParams, nanogptParams, ... }:

{
  hy3 = [
    {
      model = "openrouter/tencent/hy3-preview:free";
    }
  ];
  "ling-2.6-flash" = [
    {
      model = "openrouter/inclusionai/ling-2.6-flash:free";
    }
  ];
  "nemotoron-3-super" = [
    {
      model = "openrouter/nvidia/nemotron-3-super-120b-a12b:free";
    }
  ];
  "nemotoron-embed" = [
    {
      model = "openrouter/nvidia/llama-nemotron-embed-vl-1b-v2:free";
    }
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
