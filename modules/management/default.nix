{ config, lib, ... }:
let
  cfg = config.my.system.management;
  cfgManager = cfg.manager;
  cfgAgent = cfg.agent;

  vpnOption = {
    enable = lib.mkEnableOption "Whether to enable VPN settings";
    address = lib.mkOption {
      type = lib.types.str;
      default = "10.0.0.1/24";
      description = "VPN address of the agent";
    };
    port = lib.mkOption {
      type = lib.types.int;
      default = 51820;
      description = "VPN port of the agent";
    };
    privateKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/wireguard/private.key";
      description = "Private key file for WireGuard";
    };
    peers = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "VPN peer configuration";
      default = [];
      example = [
        {
          publicKey = ".....";
          allowedIPs = [ "192.168.0.1/32" ];
        }
      ];
    };
  };
in
{
  options.my.system.management = {
    manager = {
      enable = lib.mkEnableOption "Whether to enable manager settings";
      enableCrossCompile = lib.mkEnableOption "Whether to enable cross compile settings for building agent binaries for ARM architecture.";
      ssh = {
        user = lib.mkOption {
          type = lib.types.str;
          default = config.my.system.users.adminUser;
          description = "SSH user to connect agent";
        };
      };
      vpn = vpnOption;
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
      ssh = {
        user = lib.mkOption {
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
      vpn = vpnOption;
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
