{ config, pkgs, lib, ...}:
let
  # If enabled proxy by mistake,
  # use "https_proxy= all_proxy= sudo -E nixos-rebuild switch --flake ".?submodules=1" --impure --show-trace"
  # to rebuild to disable proxy, and restart system.
  cfg = config.my.system.networks;
in {
  options.my.system.networks = {
    hostname = lib.mkOption {
      type = lib.types.str;
      description = "hostname.";
      default = "nixos";
    };
    proxy = lib.mkOption {
      type = lib.types.str;
      description = "proxy url";
      default = builtins.getEnv "https_proxy";
      example = "https://example.com:3128";
    };
  };

  config = rec {
    networking = {
      hostName = cfg.hostname;
      firewall.enable = lib.mkDefault true; # for nixos-generators setting conflict workaround, added lib.mkDefault.
      # Disable because service is failed: https://discourse.nixos.org/t/nftables-could-not-process-rule-no-such-file-or-directory/33031
      nftables.enable = lib.mkDefault (! config.virtualisation.docker.enable); # docker does not support nftables.

      # Ensure declarative networking, but need to be enabled for runtime.
      # E.g. must be enabled for virtualbox.
      networkmanager.enable = lib.mkDefault true;

      # https://discourse.nixos.org/t/networkmanager-plugins-installed-by-default/39682
      # can use lib.mkForce to override. https://github.com/hsjobeki/nixpkgs/blob/0c9e279ffc334c4a13c9f65059546dc3425e9343/lib/modules.nix#L1163
      networkmanager.plugins = lib.mkOverride 75 [];

      # Global dhcp flag is deprecated. see https://gist.github.com/ulysses4ever/d667955933be956da75783fed8d8d0fe
      useDHCP = false;
    } // lib.optionalAttrs (cfg.proxy != "") {
      proxy = {
        default = cfg.proxy;
        noProxy = "127.0.0.1,localhost,${networking.hostName}";
      };
    };
  };
}
