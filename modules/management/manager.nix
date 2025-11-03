{ config, lib, ... }:
let
  cfg = config.my.system.management.manager;
in
{
  config = lib.mkIf cfg.enable {
    boot.binfmt.emulatedSystems = lib.optionals cfg.enableCrossCompile ["aarch64-linux"]; # To build agent binaries for ARM architecture.

    networking = {
      extraHosts = let
        hostStrings = lib.forEach cfg.agents (agent: "${agent.address} ${agent.hostname}");
      in lib.concatStringsSep "\n" hostStrings;
    } // lib.optionalAttrs cfg.vpn.enable {
      # VPN
      firewall.allowedUDPPorts = [ cfg.vpn.port ]; # VPN port
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
    };
    # Required by wireguard.
    # Some kernel disallow runtime module loading,
    # so in this case, first apply this without vpn.enable, and at last enable vpn.enable.
    boot.kernelModules = [ "wireguard" ];
  };
}
