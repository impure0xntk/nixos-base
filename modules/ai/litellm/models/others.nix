{ lib, opencodeZenParams, ... }:

{
  "trinity-large" = [
    {
      model = "openrouter/arcee-ai/trinity-large-preview:free";
      params = {};
    }
  ];
  "nemotoron-3-super" = [
    {
      model = "openrouter/nvidia/nemotron-3-super-120b-a12b:free";
      params = {};
    }
  ];
  "nemotoron-embed" = [
    {
      model = "openrouter/nvidia/llama-nemotron-embed-vl-1b-v2:free";
    }
  ];
  "minimax-m2.5" = [
    {
      model = "openai/minimax-m2.5-free";
      params = opencodeZenParams;
    }
  ];
  text-to-speech-playai-tts = [
    {
      model = "groq/playai-tts";
      params = {
      };
    }
  ];
}