# inspire: https://github.com/marcinfalkiewicz/nixos-configuration/blob/master/pkgs.nix
{ config, lib, ... }:
let
  cfg = config.my.system.desktop.rdp;
  cfgCommon = config.my.system.desktop;
in {
  options.my.system.desktop.rdp = {
    enable = lib.mkEnableOption "Whether to enable RDP.";
    port = lib.mkOption {
      type = lib.types.port;
      description = "Port for RDP.";
      default = 3389;
    };
    isLocal = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to use RDP as local connection.";
    };
  };

  config = lib.mkIf (cfgCommon.enable && cfg.enable) {
    # for RDP: https://gist.github.com/hermannolafs/c1379a090350d2dc369aeabd3c0d8de3
    # Each services.xrdp.defaultWindowManager must be set.
    #
    # The default DISPYAY number is 10, it depends on sesman.ini .
    # MEMO: This requires that xrdp sessions don't replicate, such as cleanup sessions on boot.
    services.xrdp = let
        xrdpNoCrypt = lib.optionalString cfg.isLocal ''--replace-fail "crypt_level=high" "crypt_level=none"'';
        xrdpNoCompression = lib.optionalString cfg.isLocal ''--replace-fail "bitmap_compression=true" "bitmap_compression=false"'';
        TcpSendBytes = builtins.toString (config.boot.kernel.sysctl."net.core.wmem_max" / 2);
        TcpRecvBytes = builtins.toString (config.boot.kernel.sysctl."net.core.rmem_max" / 2);
      in {
      enable = true;
      port = cfg.port;
      openFirewall = !cfg.isLocal;
      # Performance tuning: https://github.com/NixOS/nixpkgs/issues/126265
      # This RDP settings must apply only local use case!
      extraConfDirCommands= ''
        substituteInPlace $out/xrdp.ini \
          ${xrdpNoCrypt} ${xrdpNoCompression} \
          --replace-fail "#tcp_send_buffer_bytes=32768" "tcp_send_buffer_bytes=${TcpSendBytes}" \
          --replace-fail "#tcp_recv_buffer_bytes=32768" "tcp_recv_buffer_bytes=${TcpRecvBytes}"

        substituteInPlace $out/sesman.ini \
          --replace-fail "KillDisconnected=false" "KillDisconnected=true" \
          --replace-fail "FuseMountName=thinclient_drives" "FuseMountName=host_drives"
      '';
      # for RDP: https://gist.github.com/hermannolafs/c1379a090350d2dc369aeabd3c0d8de3
      # If use xsession from home-manager, delegate.
      defaultWindowManager = lib.mkDefault ''
        if test -e ~/.xsession; then
          exec ~/.xsession
        fi
      '';
    };
    # Even if KillDisconnected=true, when reboot /tmp/.xrdp/* remains as old sessions.
    # So add the tmpfiles.d config to cleanup to on boot.
    systemd.tmpfiles.settings."xrdp-sessions" = lib.mkIf config.services.xrdp.enable {
      "/tmp/.xrdp"."R!".age = "1w"; # The age is too long but enough to cleanup on boot.
    };
    # Slow RDP connections and "Can't open config file /etc/xrdp/sesman.ini" workaround.
    # https://github.com/NixOS/nixpkgs/issues/250533#issuecomment-1874141107
    environment.etc = {
      "xrdp/sesman.ini".source = "${config.services.xrdp.confDir}/sesman.ini";
    };
    # polkit color-manager settings for RDP
    # https://nixos.wiki/wiki/Polkit https://gist.github.com/mamemomonga/cfa1636a6cf41b264ad8503b64e799d4
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if ((action.id == "org.freedesktop.color-manager.create-device" ||
            action.id == "org.freedesktop.color-manager.create-profile" ||
            action.id == "org.freedesktop.color-manager.delete-device" ||
            action.id == "org.freedesktop.color-manager.delete-profile" ||
            action.id == "org.freedesktop.color-manager.modify-device" ||
            action.id == "org.freedesktop.color-manager.modify-profile")) {
          return polkit.Result.YES;
        }
      });
    '';
  };
}
