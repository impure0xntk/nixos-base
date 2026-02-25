# For github copilot:
# 1. Run litellm manually to auth device: input code
#    Use "systemctl cat --user litellm.service" ans exec ExecStart command from interactive commandline.
# 2. You can start litellm automatically.
# For details, see https://docs.litellm.ai/docs/providers/github_copilot
{ lib, githubCopilotParams, openaiParams, ... }:
let
  gptOssParams = {
    temperature = 0.6;
    top_p = 1.0;
    top_k = 0;
  };
in
{
  gpt-oss-120b = [
    {
      model = "groq/openai/gpt-oss-120b";
      params = { # additional params are unsupported
      };
    }
  ];
  gpt-oss-20b = [
    {
      model = "groq/openai/gpt-oss-20b"; # primary
      params = { # additional params are unsupported
      };
    }
    {
      model = "openrouter/openai/gpt-oss-20b:free";
      params = {
      } // gptOssParams;
    }
  ];
  "gpt-5.2" = [
    {
      model = "github_copilot/gpt-5.2";
      info.mode = "responses";
      params = {
      } // githubCopilotParams;
    }
    {
      model = "openai/gpt-5.2";
      params = {
      } // openaiParams;
    }
  ];
  "gpt-5.2-codex" = [
    {
      model = "github_copilot/gpt-5.2-codex";
      info.mode = "responses";
      params = {
      } // githubCopilotParams;
    }
    {
      model = "openai/gpt-5.2-codex";
      params = {
      } // openaiParams;
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