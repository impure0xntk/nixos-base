{ lib, opencodeZenParams, ... }:

{
  "glm-4.5-air" = [
    {
      model = "openrouter/z-ai/glm-4.5-air:free";
      params = {
      };
    }
  ];
  "step-3.5-flash" = [
    {
      model = "openrouter/stepfun/step-3.5-flash:free";
      params = {};
    }
  ];
  "trinity-large-preview" = [
    {
      model = "openrouter/arcee-ai/trinity-large-preview:free";
      params = {};
    }
  ];
  "nemotoron-3-nano" = [
    {
      model = "openrouter/nvidia/nemotron-3-nano-30b-a3b:free";
      params = {};
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