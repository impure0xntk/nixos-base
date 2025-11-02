{ config, lib, ... }:
let
  cfg = config.my.system.management.agent;
in
{
  config = lib.mkIf cfg.enable {
    users.users.${cfg.sshUser}.openssh.authorizedKeys.keys = cfg.pubKeys;
    services.openssh = {
      enable = true;
      settings = {
        AllowUsers = [ cfg.sshUser ];
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };
    services.fail2ban = {
      enable = true;
      maxretry = 5;
      ignoreIP = [
        "10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16"
        "8.8.8.8"
      ];
      bantime = "24h";
      bantime-increment = {
        enable = true;
        multipliers = "1 2 4 8 16 32 64";
        maxtime = "168h";
      };
    };
    boot.kernelModules = ["xt_multiport" ]; # https://www.reddit.com/r/NixOS/comments/1e2micc/comment/mcbbv1y/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
  };
}
