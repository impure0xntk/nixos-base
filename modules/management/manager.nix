{ config, lib, ... }:
let
  cfg = config.my.system.management.manager;
in
{
  config = lib.mkIf cfg.enable {
    boot.binfmt.emulatedSystems = lib.optionals cfg.enableCrossCompile ["aarch64-linux"]; # To build agent binaries for ARM architecture.

    home-manager.users.${cfg.sshUser}.programs.ssh.matchBlocks = builtins.listToAttrs (
      map (agent: {
        name = "${agent.hostname}";
        value = agent;
      }) cfg.agents
    );
  };
}
