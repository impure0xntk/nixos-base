{ config, lib, ... }:
let
  cfg = config.my.system.management;
  cfgManager = cfg.manager;
  cfgAgent = cfg.agent;
in
{
  options.my.system.management = {
    manager = {
      enable = lib.mkEnableOption "Whether to enable manager settings";
      sshUser = lib.mkOption {
        type = lib.types.str;
        default = config.my.system.users.adminUser;
        description = "SSH user to connect agent";
      };
      agents = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        example = [
          {
            user = "nixos";
            hostname = "localhost";
            identityFile = [ "%d/.ssh/id_ed25519" ];
          }
        ];
        default = [ ];
      };
    };
    agent = {
      enable = lib.mkEnableOption "Whether to enable agent settings";
      sshUser = lib.mkOption {
        type = lib.types.str;
        default = config.my.system.users.adminUser;
        description = "SSH user to connect agent";
      };
      pubKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Pubkey";
      };
    };
  };
  config = {
    assertions = [
      {
        assertion = (!cfgManager.enable && !cfgAgent.enable) || (cfgManager.enable != cfgAgent.enable);
        message = "my.system.management.{manager,agent} are exclusive.";
      }
    ];
  };

  imports = [
    ./manager.nix
    ./agent.nix
  ];
}
