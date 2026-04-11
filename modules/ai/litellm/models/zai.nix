{ lib, nanogptParams, ... }:
{
  "glm-4.5-air" = [
    {
      model = "openrouter/z-ai/glm-4.5-air:free";
      params = {
      };
    }
  ];
  "glm-4.6-derestricted" = [
    { model = "openai/GLM-4.6-Derestricted-v5"; params = nanogptParams; }
  ];
  "glm-4.7" = [
    { model = "openai/zai-org/glm-4.7"; params = nanogptParams; }
  ];
  "glm-4.7-flash" = [
    { model = "openai/zai-org/glm-4.7-flash"; params = nanogptParams; }
  ];
  glm-5 = [
    { model = "openai/zai-org/glm-5"; params = nanogptParams; }
  ];
  glm-5-think = [
    { model = "openai/zai-org/glm-5:thinking"; params = nanogptParams; }
  ];
}
