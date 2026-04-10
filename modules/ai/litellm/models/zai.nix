{ lib, ... }:
{
  "glm-4.5-air" = [
    {
      model = "openrouter/z-ai/glm-4.5-air:free";
      params = {
      };
    }
  ];
  "glm-4.6-derestricted" = [
    { model = "nano-gpt/GLM-4.6-Derestricted-v5"; }
  ];
  "glm-4.7" = [
    { model = "nano-gpt/zai-org/glm-4.7"; }
  ];
  glm-5 = [
    { model = "nano-gpt/zai-org/glm-5"; }
  ];
  glm-5-think = [
    { model = "nano-gpt/zai-org/glm-5:thinking"; }
  ];
}
