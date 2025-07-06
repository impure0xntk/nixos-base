# inspire: https://github.com/marcinfalkiewicz/nixos-configuration/blob/master/pkgs.nix
{ pkgs, config, lib, ...}:
let
  cfg = config.my.system.desktop.autologin;
  cfgCommon = config.my.system.desktop;

  useStartx = config.services.xserver.displayManager.sx.enable;
  ttyNumber = builtins.toString config.services.xserver.tty;

  # for startx
  # https://github.com/NixOS/nixpkgs/issues/177924
  # use sx instead of startx to workaround https://discourse.nixos.org/t/x11-not-working-with-scudo/26441
  # sx needs XDG_CONFIG_HOME/sx/sxrc as executable. It is defined by home/common/default.nix
  autoStartxService = user: {
    enable = useStartx;
    description = "X11 session for ${user}";
    after = [ "graphical.target" "systemd-user-sessions.service" ];
    wantedBy = [ "graphical.target" ];
    environment = { XDG_SESSION_TYPE = "x11"; };
    preStart = "${pkgs.kbd}/bin/chvt ${ttyNumber}";
    script = ''
      sx
      logout
    '';
    startLimitIntervalSec = 30;
    startLimitBurst = 3;
    serviceConfig = {
      User = user;
      WorkingDirectory = "~";
      PAMName = "login";
      TTYPath = "/dev/tty${ttyNumber}";
      StandardInput = "tty";
      UnsetEnvironment = "TERM";
      UtmpIdentifier = "tty${ttyNumber}";
      UtmpMode = "user";
      StandardOutput = "journal";
    };
  };
in {
  options.my.system.desktop.autologin = {
    enable = lib.mkEnableOption "Whether to enable desktop environment.";
    user = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Auto-login user.";
    };
    singleUser = lib.mkEnableOption "Whether to enable single user mode. If enabled, nobody can graphical-login except config.my.system.desktop.autologin.user.";
  };

  config = lib.mkIf (cfgCommon.enable && cfg.enable) {
    assertions = [
      {
        assertion = "${cfg.user}" != "";
        message = "Must set my.system.desktop.autologin.user .";
      }
      {
        assertion = builtins.hasAttr "${cfg.user}" config.users.users;
        message = "Auto-login user could not found in config.users.users .";
      }
      {
        assertion = config.users.users.${cfg.user}.isNormalUser;
        message = "Auto-login user should be normal user.";
      }
    ];

    services.displayManager.autoLogin = {
      enable = ! useStartx;
      user = cfg.user;
    };

    systemd.services."autostartx-defaultUser" = lib.mkIf cfg.singleUser (autoStartxService cfg.user);

    # disable login manager
    services.greetd = {
      enable = lib.mkForce (! cfg.singleUser);
      settings.initial_session = {
        command = "sx";
        user = cfg.user;
      };
    };
  };
}

