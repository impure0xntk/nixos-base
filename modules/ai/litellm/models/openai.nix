# For github copilot:
# 1. Run litellm manually to auth device: input code
#    Use "systemctl cat --user litellm.service" ans exec ExecStart command from interactive commandline.
# 2. You can start litellm automatically.
# For details, see https://docs.litellm.ai/docs/providers/github_copilot
{ lib, githubCopilotParams, openaiParams, nanogptParams, ... }:
let
in
{
  gpt-oss-120b = [
    {
      model = "openai/openai/gpt-oss-120b"; params = {
        order = 1;
      } // nanogptParams;
    }
    {
      model = "groq/openai/gpt-oss-120b";
      params = { # additional params are unsupported
        order = 2;
      };
    }
    {
      model = "openrouter/openai/gpt-oss-120b:free";
      params = {
        order = 3;
      };
    }
  ];
  gpt-oss-20b = [
    {
      model = "groq/openai/gpt-oss-20b"; # primary
      params = { # additional params are unsupported
        order = 1;
      };
    }
    {
      model = "openrouter/openai/gpt-oss-20b:free";
      params = {
        order = 2;
      };
    }
  ];
  "gpt-5.4" = [
    {
      model = "github_copilot/gpt-5.4";
      info.mode = "responses";
      params = {
      } // githubCopilotParams;
    }
    {
      model = "chatgpt/gpt-5.4";
      info.mode = "responses";
      params = {
      };
    }
  ];
  "gpt-5.3-codex" = [
    {
      model = "github_copilot/gpt-5.3-codex";
      info.mode = "responses";
      params = {
      } // githubCopilotParams;
    }
    {
      model = "chatgpt/gpt-5.3-codex";
      info.mode = "responses";
      params = {
      };
    }
  ];
  speech-to-text-whisper-large-v3 = [
    {
      model = "groq/whisper-large-v3";
      params = {
      };
    }
  ];
  speech-to-text-whisper-large-v3-turbo = [
    {
      model = "groq/whisper-large-v3-turbo";
      params = {
      };
    }
  ];
}