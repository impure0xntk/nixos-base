{ lib, ... }:

{
  "glm-4.5-air" = [
    {
      model = "openrouter/z-ai/glm-4.5-air:free";
      params = {
      };
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