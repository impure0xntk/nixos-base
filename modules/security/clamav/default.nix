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
  environment.systemPackages = [ purgeQuarantinedFiles ];
  services = {
    clamav = {
      daemon = {
        enable = true;
        settings = {
          OnAccessIncludePath = suspects.userDirectories;
          OnAccessPrevention = false;
          OnAccessExtraScanning = true;
          OnAccessExcludeUname = "clamav";
          User = "clamav";
          ExcludePath = suspects.systemExcludeDirectories ++ suspects.userExcludeDirectories;
          OnAccessExcludePath =
            suspects.systemExcludeDirectories ++ suspects.userExcludeDirectories;
        };
      };
      updater = {
        enable = true;
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
        enable = true;
        interval = updateInterval;
      };
      scanner = {
        enable = true;
        interval = scannerInterval;
        scanDirectories = suspects.systemDirectories ++ suspects.userDirectories;
      };
    };
  };

  # Resource limit.
  systemd.slices.system-clamav.sliceConfig = {
    MemoryMax = "1600M";
    CPUQuota = "25%";
  };

  systemd.services.clamav-daemon.serviceConfig.ExecStartPre =
    lib.mkIf config.services.clamav.daemon.enable (pkgs.writeShellScript "daemon-start" ''
    # Ready for quarantine.
    test -d ${quarantineDirectory} || install -o clamav -g clamav -m 700 -d ${quarantineDirectory}
  '');

  # Override for quarantine
  systemd.services.clamdscan.serviceConfig.ExecStart =
    lib.mkIf config.services.clamav.scanner.enable (lib.mkForce (pkgs.writeShellScript "scan" ''
      ${pkgs.systemd}/bin/systemd-cat --identifier=clamdscan \
        ${config.services.clamav.package}/bin/clamdscan \
        --multiscan --fdpass --infected --allmatch \
        --move=${quarantineDirectory} \
        ${lib.concatStringsSep " " config.services.clamav.scanner.scanDirectories}
    ''));

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
}
