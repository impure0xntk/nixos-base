# For github copilot:
# 1. Run litellm manually to auth device: input code
#    Use "systemctl cat --user litellm.service" ans exec ExecStart command from interactive commandline.
# 2. You can start litellm automatically.
# For details, see https://docs.litellm.ai/docs/providers/github_copilot
{ lib, githubCopilotParams, ... }:
let
in
{
  "claude-sonnet-4.5" = [
    {
      model = "github_copilot/claude-4.5-sonnet";
      params = {
      } // githubCopilotParams;
    }
  ];
  "claude-opus-4.5" = [
    {
      model = "github_copilot/claude-opus-4.5";
      params = {
      } // githubCopilotParams;
    }
  ];
}