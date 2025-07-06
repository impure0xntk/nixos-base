{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.types;
let
  cfg = config.my.system.secrets-store;
  cfgDevUser = config.my.system.users.devUsers;
in
{
  options.my.system.secrets-store = {
    sopswarden.enable = mkEnableOption "Enable Sopswarden for managing secrets.";
  };

  config = {
    assertions = [
      {
        assertion = !(cfg.sopswarden.enable && config.system.switch.enable && config.my.system.develop.nix.enable && cfgDevUser == [ ]);
        message = "If Sopswarden is enabled, there must be at least one developer user defined.";
      }
      {
        assertion = !cfg.sopswarden.enable || (builtins.stringLength (builtins.getEnv "SECRETS_STORE_BITWARDEN_EMAIL") > 0);
        message = "SECRETS_STORE_BITWARDEN_EMAIL environment variable must be set.";
      }
    ];

    sops = {
      age = {
        generateKey = true;
        keyFile = "/var/lib/sops-nix/key.txt";
      };
    };

    # sopswarden.
    # The nix developers will use sopswarden to access secrets.
    # The part of settings of sopswarden and rbw are defined by develop/nix .
    services.sopswarden = {
      enable = cfg.sopswarden.enable;

      secrets = {
        # Simple secrets - just specify the Bitwarden item name
        wifi-password = "Home WiFi";
        database-url = "Production Database";
      };

      ageKeyFile = config.sops.age.keyFile;
    };
    home-manager.users.${config.my.system.users.adminUser} = lib.mkIf config.system.switch.enable {
      programs.rbw = lib.mkIf cfg.sopswarden.enable {
        enable = true;
        settings = {
          email = builtins.getEnv "SECRETS_STORE_BITWARDEN_EMAIL";
          lock_timeout = 3600;
          pinentry = config.services.gpg-agent.pinentry.package;
        };
      };
    };

  };
}
