{ config, lib, ...}:
let
  cfg = config.my.system.users;

  traceSeq = seq: lib.my.traceSeqWith "my.system.users" seq;

  adminUserAttrs = {
    ${cfg.adminUser} = {
      extraGroups = [ cfg.adminGroup ];
    };
  };
  devUsersAttrs = lib.genAttrs cfg.devUsers (user: {
    extraGroups = [ cfg.devGroup ];
  });

  allUsersAttrs = lib.recursiveUpdate adminUserAttrs devUsersAttrs;
  allUsersAttrsDefault = lib.concatMapAttrs (user: value: {
    ${user} = value // {
      group = user;
      isNormalUser = true;

      linger = true; # systemd user
    };
  }) allUsersAttrs;
  allGroupAttrsDefault = lib.mapAttrs (user: _: {}) allUsersAttrs;
in {
  options.my.system.users = {
    adminUser = lib.mkOption {
      type = lib.types.str;
      default = "nixos";
      description = "System administrator user.";
    };
    adminGroup = lib.mkOption {
      type = lib.types.str;
      default = "wheel";
      description = "Group to manage system.";
    };
    devUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of developer users.";
    };
    devGroup = lib.mkOption {
      type = lib.types.str;
      default = "developer";
      description = "Group to manage developer.";
    };
    users = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {});
      default = {};
      description = "List of users. See https://search.nixos.org/options?channel=${config.system.stateVersion}&show=users.users";
    };
  };

  config = {
    nix.settings = traceSeq {
      trusted-users = ["root" "@${cfg.adminGroup}"];
      allowed-users = ["@${cfg.devGroup}"]; # for nix control and home-manager activation
    };
    users = traceSeq {
      mutableUsers = false;
      users = allUsersAttrsDefault;
      groups = allGroupAttrsDefault
        // (lib.optionalAttrs (cfg.devGroup != "") {
        ${cfg.devGroup} = {};
      });
    };
  };
}
