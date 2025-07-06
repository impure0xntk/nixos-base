{ config, lib, ... }:
let
  cfg = config.my.system.management.agent;
in
{
  config = lib.mkIf cfg.enable {
    users.users.${cfg.sshUser}.openssh.authorizedKeys.keys = cfg.pubKeys;
    services.openssh = {
      enable = true;
      settings.AllowUsers = [ cfg.sshUser ];
    };
  };
}
