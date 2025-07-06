{ config, lib, ... }:
let
  cfg = config.my.system.management.manager;
in
{
  config = lib.mkIf cfg.enable {
    home-manager.users.${cfg.sshUser}.programs.ssh.matchBlocks = builtins.listToAttrs (
      map (agent: {
        name = "${agent.hostname}";
        value = agent;
      }) cfg.agents
    );
  };
}
