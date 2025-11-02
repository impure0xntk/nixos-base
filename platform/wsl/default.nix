{ config, pkgs, lib,
... }:
let
  cfg = config.my.system.platform.settings.wsl;

  normalUsers = lib.filterAttrs (n: v: v.isNormalUser) config.users.users;

  # '/run/user/1000' workaround.
  # https://github.com/nix-community/NixOS-WSL/issues/346#issuecomment-1894895912
  #
  # If want to remove, remove this to avoid "rm: cannot remove '/run/user/1000': Device or resource busy"
  fixUserRuntimeDirServices = lib.mapAttrsToList (n: v: # To run on boot
  let
    genScript = user: basedir: ''
      USER_ID="$(id -u ${user})"
      GROUP_ID="$(id -g ${user})"
      if test -z "$USER_ID" || test -z "$GROUP_ID"; then
        exit 1
      fi
      if ! test -e "${basedir}/$USER_ID"; then # skip
        # FIXME: for gdm, mkdir before login. This is bad solution
        mkdir -p ${basedir}/$USER_ID
      fi
      RUNTIME_DIR_OWNER="$(${pkgs.coreutils-full}/bin/stat -c '%U' ${basedir}/$USER_ID 2>/dev/null)"
      if [ "''${RUNTIME_DIR_OWNER:-}" != "${user}" ]; then
        ${pkgs.coreutils-full}/bin/chown $USER_ID:$GROUP_ID ${basedir}/$USER_ID
        ${pkgs.coreutils-full}/bin/chmod 700 ${basedir}/$USER_ID
        ${pkgs.systemd}/bin/systemctl restart --wait user@$USER_ID
      fi
    '';
  in
    {
      "fix-xdg-runtime-dir-${n}" = {
        description = "Fix XDG_RUNTIME_DIR on-boot for user ${n}.";
        wantedBy = [ "multi-user.target" ];
        script = genScript n "/run/user";
      };
    }
  ) normalUsers;
in {
  imports = [
    ../vm
    ];

  options.my.system.platform.settings.wsl.defaultUser = lib.mkOption {
    type = lib.types.str;
    default = config.my.system.users.adminUser;
    description = "Default user for WSL.";
  };

  config = {
    # Set platform type for other modules.
    my.system.platform.type = "wsl";

    wsl = {
      enable = true;
      defaultUser = cfg.defaultUser;
      useWindowsDriver = true;

      wslConf = {
        network.generateHosts = false;
        network.generateResolvConf = true;
        interop.appendWindowsPath = false;
      };
    };
    users.users.${config.wsl.defaultUser} = {
      linger = true; # For /run/user/$(id -u) https://blog.n-z.jp/blog/2020-06-02-systemd-user-bus.html
    };

    # avoid conflict with hardened profile apparmor.
    # When wsl.generateResolvConf = true, NixOS-WSL sets environment.etc.enable only, and apparmor crowls each etc.source,
    # Thus set empty path to avoid apparmor error.
    # https://github.com/nix-community/NixOS-WSL/blob/be1a6b2e4ddc34b9b6a297e7df2f2a2ecee24690/modules/wsl-distro.nix#L109
    # https://github.com/NixOS/nixpkgs/blob/a781ff33ae258bbcfd4ed6e673860c3e923bf2cc/nixos/modules/security/apparmor/includes.nix#L11
    environment.etc."resolv.conf".source = lib.mkIf (config.wsl.wslConf.network.generateResolvConf && config.security.apparmor.enable) ./.;
    boot.kernel.sysctl."net.core.bpf_jit_enable" = null; # hardened

    hardware.graphics.enable = lib.mkForce config.services.xserver.enable; # nixos-wsl sets true, but in headless it is not necessary.

    # https://news.mynavi.jp/article/20231009-2788372/
    fonts.fontconfig.localConf = ''
      <fontconfig>
        <dir>/mnt/c/Windows/Fonts</dir>
      </fontconfig>
    '';

    # Disable X autorun if uses xserver (because must use xrdp).
    # https://github.com/NixOS/nixpkgs/issues/311683
    # If remove this, you must care /run/user/{132,1000} permission/owner mismatch ! (may caused by the timing of boot xserver)
    systemd.defaultUnit = lib.mkIf config.services.xserver.enable (lib.mkForce "multi-user.target");

    # must disable systemd-networkd
    systemd.network.enable = lib.mkForce false;

    # Unnecessary
    networking.networkmanager.enable = lib.mkForce false;
    networking.nftables.enable = lib.mkForce false;
    i18n.inputMethod.enable = lib.mkForce false;

    # In now 2025/2, wsl kernel has no AppArmor support.
    # If want to use it, build custom kernel.
    security.apparmor.enable = lib.mkForce false;

    systemd.tmpfiles.settings = {
      # For X11 without wslg, overwrite NixOS-WSL settings.
      # https://github.com/nix-community/NixOS-WSL/pull/371 , https://github.com/nix-community/NixOS-WSL/commit/3257ad7f173b0314c8a42fec450fa6556495b97c
      "10-wslg-x11" = lib.mkIf config.services.xserver.enable (lib.mkForce {});
      "91-cleanup-nixos-wsl-specific-dirs" = {
        # wsl persists /run/user, so remove.
        # Thus when boot root creates /run/user/(each user).
        # Must fix chown using systemd service as "fix-*-xdg-runtime-dir" below.
        "/run/user" = {
          "R!" = {
            argument = "";
          };
        };
      };
    };
    systemd.services = {
      # Wrong mode '/tmp/.X11-unix' workaround. When reboot, set to 0755 by default, but expect 1777.
      fix-x11-unix-mode-without-wslg = {
        enable = config.services.xserver.enable;
        description = "Fix /tmp/.X11-unix mode on-boot.";
        wantedBy = [ "multi-user.target" ];
        script =
          let
            wslgUnixDomainSocket = "/mnt/wslg/.X11-unix/X0";
            echo = text: "echo ${text} | ${pkgs.systemd}/bin/systemd-cat --identifier=\"fix-x11-unix-mode-without-wslg\" -p warning";
          in ''
            if test -S ${wslgUnixDomainSocket}; then
              ${echo "Both X and WSLg are enabled !!"}
              ${echo "Disable WSLg from Windows default user %USERPROFILE%/.wslconfig !!"}
              exit 1
            fi

            EXPECTED_MODE="1777"
            X11_UNIX_DIR_MODE="$(${pkgs.coreutils-full}/bin/stat -c '%a' /tmp/.X11-unix 2>/dev/null)"
            if [ "''${X11_UNIX_DIR_MODE:-}" != "$EXPECTED_MODE" ]; then
              ${pkgs.coreutils-full}/bin/chmod $EXPECTED_MODE /tmp/.X11-unix
            fi
          '';
      };

      check-cgroupv2 = {
        enable = true;
        description = "Check whether cgroupv2 is enabled";
        wantedBy = [ "multi-user.target" ];
        script =
          let
            echo = text: "echo ${text} | ${pkgs.systemd}/bin/systemd-cat --identifier=\"check-cgroupv2\" -p warning";
          in ''
            if test -d /sys/fs/cgroup/memory; then
              ${echo "To enable cgorupv2, the following setting is required for %USERPROFILE%/.wslconfig .!!"}
              ${echo "'kernelCommandLine = cgroup_no_v1=all systemd.unified_cgroup_hierarchy=1'"}
              exit 1
            fi
          '';
      };

    } // lib.mergeAttrsList fixUserRuntimeDirServices;

    # Graphic hardware acceration.
    # https://github.com/nix-community/NixOS-WSL/issues/454#issuecomment-2284226904
    #
    # Note: Now 2024/12 If enabled the following issue sometimes occurs but almost working correctly.
    #  misc dxg: dxgk: dxgkio_is_feature_enabled: Ioctl failed: -{2,22}
    # https://github.com/microsoft/WSL/issues/9099
    environment.sessionVariables.LD_LIBRARY_PATH = lib.optionals config.wsl.useWindowsDriver [ "/run/opengl-driver/lib" ];

    # Clipboard
    nixpkgs.overlays = [
      (final: prev: {
        xsel = pkgs.writeShellApplication {
          name = prev.xsel.pname;
          runtimeInputs = [ pkgs.nkf ];
          # Convert charset: https://qiita.com/suzuki-navi/items/f340c69ccada84a3ece3
          text = ''
            ${pkgs.nkf}/bin/nkf -Ws | /mnt/c/Windows/System32/clip.exe
          '';
        };
      })
    ];
    environment.systemPackages = with pkgs; [
      xsel # WSL is able to use Windows clipboard regardless of GUI
    ];
  };
}
