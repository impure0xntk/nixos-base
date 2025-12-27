{ config, lib, ... }:
let
  cfg = config.my.system.management.agent;
in
{
  config = lib.mkIf cfg.enable {
    users.users.${cfg.ssh.user}.openssh.authorizedKeys.keys = cfg.ssh.pubKeys;
    services.openssh = {
      enable = true;
      ports = [ 20022 ]; # Change SSH port to avoid automated attacks.
      settings = {
        AllowUsers = [ cfg.ssh.user ];
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
    services.fail2ban = {
      enable = true;
      maxretry = 3;
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

    networking = {
      # fail2ban
      nftables.enable = true;
    } // (lib.optionalAttrs cfg.vpn.enable {
      # VPN
      firewall = {
        allowedUDPPorts = [
          cfg.vpn.port
          53 # DNS port for VPN use
        ]; # VPN port

        interfaces.wg0.allowedTCPPorts = cfg.vpn.allowedTCPPorts or [] ++ [
          53 # DNS port for VPN use
        ];
      };

      wireguard = {
        enable = true;
        interfaces.wg0 = {
          ips = [ cfg.vpn.address ];
          listenPort = cfg.vpn.port;
          privateKeyFile = cfg.vpn.privateKeyFile;
          mtu = cfg.vpn.mtu;

          peers = cfg.vpn.peers;
        };
      };
    });
    # Required by wireguard.
    # Some kernel disallow runtime module loading,
    # so in this case, first apply this without vpn.enable, and at last enable vpn.enable.
    boot.kernelModules = [ "wireguard" ];
  };
}
