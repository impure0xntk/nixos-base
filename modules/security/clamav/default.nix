# Inspire: https://github.com/colemickens/nixcfg/blob/da7474d9d42f5714a1064260154cfd6e97dfcba7/mixins/clamav.nix
# TODO: notify after detected infected file.
{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.my.system.security.clamav;

  # See https://github.com/NixOS/nixpkgs/blob/nixos-25.05/nixos/modules/services/security/clamav.nix#L13
  toKeyValue = lib.generators.toKeyValue {
    mkKeyValue = lib.generators.mkKeyValueDefault { } " ";
    listsAsDuplicateKeys = true;
  };
  clamdConfigFile = pkgs.writeText "clamd.conf" (toKeyValue config.services.clamav.daemon.settings);

  # TODO: consider enable.
  # On-access scan is currently(2025/6) unstable about the following settings:
  # * exclude directory: https://github.com/Cisco-Talos/clamav/issues/1412
  enableOnacc = false;
  
  genUserVscodeExcludes = import ./excludes/vscode.nix;

  normalUsers = attrsets.filterAttrs (_: config: config.isNormalUser) config.users.users;
  suspects = rec {
    systemDirectories = [
      "/var/lib"
      "/etc"
      "/var/tmp"
    ];
    systemExcludeDirectories = [
      quarantineDirectory
    ];
    userDirectories = attrsets.mapAttrsToList (_: config: config.home) normalUsers;
    userExcludeDirectories = lib.concatMap (dir:
      (lib.concatMap (basedir: genUserVscodeExcludes lib basedir)
        [
          "${dir}/.vscode/extensions"
          "${dir}/.vscode-server/extensions"
        ])
    ) userDirectories;
  };
  quarantineDirectory = "/var/lib/clamav/quarantine";

  updateInterval = "weekly";
  scannerInterval = "*-*-* 12:30:00"; # lunch time

  purgeQuarantinedFiles = pkgs.writeShellScriptBin "clamav-purge-quarantined-files" ''
    if [ "$EUID" -ne 0 ]; then
      echo "Please run as root" >&2
      exit 1
    fi
    for file in ${quarantineDirectory}/*; do
      if test -e $file; then
        rm $file
        echo "Removed $file" >&2
      fi
    done
  '';
in
{
  options.my.system.security.clamav = {
    memoryMax = lib.mkOption {
      type = lib.types.str;
      default = "16000M";
      description = "The maximum memory usage for ClamAV remote access.";
    };
    remote = {
      enable = lib.mkEnableOption "Whether to enable ClamAV remote access.";
      server = {
        enable = lib.mkEnableOption "Whether to enable ClamAV antivirus.";
        host = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
          description = "The host address for the ClamAV server to bind to.";
        };
        port = lib.mkOption {
          type = lib.types.int;
          default = 3310;
          description = "The port for the ClamAV server to listen on.";
        };
      };
      client = {
        enable = lib.mkEnableOption "Whether to enable ClamAV client utilities.";
        host = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
          description = "The host address of the ClamAV server to connect to.";
        };
        port = lib.mkOption {
          type = lib.types.int;
          default = 3310;
          description = "The port of the ClamAV server to connect to.";
        };
      };
    };
    notification = {
      enable = lib.mkEnableOption "Whether to enable notification after detecting infected files.";
      commandGenerator = lib.mkOption {
        type = lib.types.str;
        default = "true";
        description = ''
          The command to execute for notification when an infected file is detected.
          The result of the scan command will be provided via standard input.
        '';
      };
    };
  };
  config = {
    environment.systemPackages = [ purgeQuarantinedFiles ];
    services = {
      clamav = let
        enableServer = if cfg.remote.enable then cfg.remote.server.enable else true;
        enableClient = if cfg.remote.enable then cfg.remote.client.enable else true;
      in {
        daemon = {
          enable = enableServer;
          settings = {
            OnAccessIncludePath = suspects.userDirectories;
            OnAccessPrevention = false;
            OnAccessExtraScanning = true;
            OnAccessExcludeUname = "clamav";
            User = "clamav";
            ExcludePath = suspects.systemExcludeDirectories ++ suspects.userExcludeDirectories;
            OnAccessExcludePath =
              suspects.systemExcludeDirectories ++ suspects.userExcludeDirectories;
            TCPSocket = lib.mkIf cfg.remote.enable (if cfg.remote.server.enable then cfg.remote.server.port
              else (if cfg.remote.client.enable then cfg.remote.client.port else 3310));
            TCPAddr = lib.mkIf cfg.remote.enable (if cfg.remote.server.enable then cfg.remote.server.host
              else (if cfg.remote.client.enable then cfg.remote.client.host else "127.0.0.1"));
          };
        };
        updater = {
          enable = enableServer;
          interval = updateInterval;
          settings = lib.optionalAttrs (config.networking.proxy.default != null) (
            let
              proxy = lib.my.separateHostAndPort config.networking.proxy.default;
            in
            {
              HTTPProxyServer = proxy.schemaAndHost;
              HTTPProxyPort = proxy.port;
            }
          );
        };
        fangfrisch = {
          # may be slow at startup: https://github.com/flyingcircusio/fc-nixos/blob/0aea3732ed1eb55c900cfe792de6f9ca2c96d0e0/nixos/roles/antivirus.nix
          enable = enableServer;
          interval = updateInterval;
        };
        scanner = {
          enable = enableClient;
          interval = scannerInterval;
          scanDirectories = suspects.systemDirectories ++ suspects.userDirectories;
        };
      };
    };

    # Official option does not support config generation when enable clamdscan only.
    environment.etc."clamav/clamd.conf".source = lib.mkForce clamdConfigFile;

    # Resource limit.
    systemd.slices.system-clamav.sliceConfig = {
      MemoryMax = cfg.memoryMax;
      CPUQuota = "25%";
    };

    systemd.services.clamav-daemon.serviceConfig = lib.mkIf config.services.clamav.daemon.enable {
      ExecStartPre =
        lib.mkIf config.services.clamav.daemon.enable (pkgs.writeShellScript "daemon-start" ''
        # Ready for quarantine.
        test -d ${quarantineDirectory} || install -o clamav -g clamav -m 700 -d ${quarantineDirectory}
      '');
      PrivateNetwork = lib.mkForce "no"; # for remote access
      Restart = "on-failure";
    };

    systemd.sockets.clamav-daemon.listenStreams = lib.mkIf cfg.remote.server.enable (lib.mkForce [
      config.services.clamav.daemon.settings.LocalSocket
      (toString cfg.remote.server.port)
    ]);


    # Official config cannot set only clamdscan.
    systemd.timers.clamdscan = lib.mkIf config.services.clamav.scanner.enable {
      description = "Timer for ClamAV virus scanner";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = config.services.clamav.scanner.interval;
        Unit = "clamdscan.service";
      };
    };
    systemd.services.clamdscan = lib.mkIf config.services.clamav.scanner.enable (lib.mkForce {
      description = "ClamAV virus scanner";
      documentation = [ "man:clamdscan(1)" ];
      after = lib.optionals config.services.clamav.updater.enable [ "clamav-freshclam.service" ];
      wants = lib.optionals config.services.clamav.updater.enable [ "clamav-freshclam.service" ];

      serviceConfig = {
        Type = "oneshot";
        Slice = "system-clamav.slice";

        # Override for quarantine
        ExecStart = let
          scanCommand = additionalOptions: ''
            ${pkgs.systemd}/bin/systemd-cat --identifier=clamdscan \
              ${config.services.clamav.package}/bin/clamdscan \
              --multiscan --fdpass --infected --allmatch \
              --move=${quarantineDirectory} \
              ${additionalOptions} \
              ${lib.concatStringsSep " " config.services.clamav.scanner.scanDirectories}'';
          scanAndNotifyCommand = if cfg.notification.enable
            then ''
              TMPFILE="$(mktemp)"
              ${scanCommand "--log=\"$TMPFILE\""}
              RETURN_CODE=$?
              cat "$TMPFILE" >&2
              if test $RETURN_CODE -ne 0 && test -s "$TMPFILE"; then
                cat "$TMPFILE" | ${cfg.notification.commandGenerator}
              else
                echo "No output found."
              fi
            '' else scanCommand "";
        in pkgs.writeShellScript "scan" scanAndNotifyCommand;
      };
    });

    systemd.services.clamav-clamonacc = lib.mkIf enableOnacc {
      description = "ClamAV daemon (clamonacc)";
      after = [
        "clamav-freshclam.service"
        "clamav-fangfrisch.service"
        "clamav-daemon.service"
      ];
      requires = [ "clamav-daemon.service" ];
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [ "/etc/clamav/clamd.conf" ];

      serviceConfig = {
        Type = "simple";
        # https://bbs.archlinux.org/viewtopic.php?id=267222
        ExecStart = pkgs.writeShellScript "onacc-start" ''
          # Wait for clamd to start.
          while [ ! -S /run/clamav/clamd.ctl ]; do
            sleep 1
          done

          ${pkgs.systemd}/bin/systemd-cat --identifier=clamav-clamonacc \
            ${pkgs.clamav}/bin/clamonacc -F --fdpass \
            --move=${quarantineDirectory}
        '';
        PrivateTmp = "yes";
        PrivateDevices = "yes";
        PrivateNetwork = "yes";
        # To terminate quickly
        TimeoutStopSec = 3;
      };
    };
  };
}
