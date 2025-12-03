{ lib, ... }:

{
  "glm-4.5-air" = [
    {
      model = "openrouter/z-ai/glm-4.5-air:free";
      params = {
      };
    }
  ];
  "nova-2-lite" = [
    {
      model = "openrouter/amazon/nova-2-lite-v1:free";
      params = {
      };
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