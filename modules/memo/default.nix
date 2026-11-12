{ config, pkgs, lib, ... }:

let
  cfg = config.my.system.memo;

  memos = pkgs.my.memos; # TODO: change to pkgs.unstable after bumped to 26.11 in nixpkgs

  memosConfigDir = pkgs.runCommand "memos-config" {}
    ''
      mkdir -p $out
      ${lib.concatStringsSep "\n" (lib.attrValues (lib.mapAttrs (name: value: ''
        mkdir -p "$out/$(dirname "${name}.json")"
        cp ${pkgs.writeText "${name}.json" (builtins.toJSON value)} "$out/${name}.json"
      '') cfg.settings))}
    '';
in {
  options.my.system.memo = {
    enable = lib.mkEnableOption "Whether to enable memo (Memos server).";
    host = lib.mkOption {
      type = lib.types.str;
      description = "Host address for Memos server access.";
      default = "127.0.0.1";
    };
    port = lib.mkOption {
      type = lib.types.port;
      description = "Port for Memos server.";
      default = 8080;
    };
    dataDir = lib.mkOption {
      type = lib.types.path;
      description = "Host path for Memos data directory.";
      default = "/var/lib/memos";
    };
    settings = lib.mkOption {
      type = lib.types.attrsOf (lib.types.anything);
      description = ''
        Memos declarative configuration. Each attribute is written as a
        separate JSON file in a Nix store directory and applied at service
        startup with \`memos config apply\` (ExecStartPost).
        See https://usememos.com/docs/configuration/declarative-configuration
      '';
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.memos = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];
      description = "Memos, a privacy-first, lightweight note-taking solution";
      serviceConfig = {
        Type = "simple";
        RestartSec = 60;
        LimitNOFILE = 65536;
        NoNewPrivileges = true;
        LockPersonality = true;
        RemoveIPC = true;
        ReadWritePaths = [
          cfg.dataDir
        ];
        DynamicUser = true;
        ProtectSystem = "strict";
        PrivateUsers = true;
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectHostname = true;
        ProtectClock = true;
        UMask = "0077";
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        ProtectProc = "invisible";
        RuntimeDirectory = "memos";
        StateDirectory = "memos";
        SystemCallFilter = [
          " " # This is needed to clear the SystemCallFilter existing definitions
          "~@reboot"
          "~@swap"
          "~@obsolete"
          "~@mount"
          "~@module"
          "~@debug"
          "~@cpu-emulation"
          "~@clock"
          "~@raw-io"
          "~@privileged"
          "~@resources"
        ];
        CapabilityBoundingSet = [
          " " # Reset all capabilities to an empty set
        ];
        RestrictAddressFamilies = [
          " " # This is needed to clear the RestrictAddressFamilies existing definitions
          "none" # Remove all addresses families
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
        ];
        DevicePolicy = "closed";
        ProtectKernelLogs = true;
        SystemCallArchitectures = "native";
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        ExecStart = lib.getExe memos;
        EnvironmentFile = pkgs.writeText "memos-envfile" ''
          MEMOS_ADDR=${cfg.host}
          MEMOS_PORT=${toString cfg.port}
          MEMOS_DATA=${cfg.dataDir}
          MEMOS_DRIVER=sqlite
          MEMOS_INSTANCE_URL=http://${cfg.host}:${toString cfg.port}
        '';
        # Apply declarative configuration after the server has started and
        # created its database. Settings come from a Nix store directory,
        # not /etc, so they remain readable under ProtectSystem = "strict".
        ExecStartPost = ''
          ${lib.getExe memos} config apply --config-dir ${memosConfigDir}
        '';
      };
    };
  };
}
