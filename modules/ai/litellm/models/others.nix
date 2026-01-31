{ lib, ... }:

{
  "glm-4.5-air" = [
    {
      model = "openrouter/z-ai/glm-4.5-air:free";
      params = {
      };
    }
  ];
  "glm-4.7" = [
    {
      model = "openai/glm-4.7-free";
      params = {
        api_base = "https://opencode.ai/zen/v1";
        api_key = "os.environ/OPENCODE_ZEN_API_KEY";
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