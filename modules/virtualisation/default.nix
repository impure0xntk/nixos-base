attrs@{ config, lib, ...}:
with lib;
with lib.types;
with lib.my;

let
  cfg = config.my.system.virtualisation;
in {
  options.my.system.virtualisation = {
    allowedUsers = mkOption {
      type = listOf str;
      default = config.my.system.users.devUsers;
      description = "List of users allowed to use virtualisation.";
    };
  };
  # These modules are setting only.
  # If want to use them, set each settings to enable.
  config = lib.my.importDirs (attrs // {
    path = ./.;
    allowedUsers = cfg.allowedUsers;
  });
}
