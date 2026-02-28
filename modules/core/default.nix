# headless is the _module.args to workaround of infinite-recursion of "imports".
# https://discourse.nixos.org/t/yet-another-infinite-recursion-problem-configurable-imports/28791/10
#
# To add decrypted derivations, any changes must be exist.
# Thus, This comment must be committed.
{
  config,
  lib,
  modulesPath,
  ...
}:
let
  cfg = config.my.system.core;
in
{
  options = {
    my.system.core = {
      mutableSystem = lib.mkEnableOption "Whether to enable mutable system.";
      headless = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to enable headless system.";
      };
    };
  };
  config = {
    system = {
      stateVersion = config.system.nixos.release;
      activatable = cfg.mutableSystem;
      switch.enable = cfg.mutableSystem;
    };
    nix = {
      enable = config.system.activatable;
      settings = {
        auto-optimise-store = true;
        experimental-features = [
          "nix-command"
          "flakes"
        ];
      };
      daemonCPUSchedPolicy = "idle";
    };
    programs.nh = {
      # nix CLI helper
      enable = true;
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep 5 --keep-since 7d";
      };
    };
    boot.kernelParams =
      [
        # For cgroupv2
        "systemd.unified_cgroup_hierarchy=1"
        "cgroup_no_v1=all"
      ]
      ++ (lib.optionals cfg.mutableSystem [
        # panic/rescue behavior
        # Since we can't manually respond to a panic, just reboot.
        "panic=1"
        "boot.panic_on_fail"
      ]);
    systemd.enableEmergencyMode = lib.mkDefault cfg.mutableSystem;

    boot.tmp.useTmpfs = false; # nix build no disk space workaround, don't use tmpfs

    # udev: device management.
    # https://discourse.nixos.org/t/enable-none-in-the-i-o-scheduler/36566/7 https://discourse.nixos.org/t/enable-none-in-the-i-o-scheduler/36566/7
    services.udev = {
      enable = lib.mkOverride 75 true;
      # change io scheduler to mq-deadline .
      extraRules = ''
        ACTION=="add|change", KERNEL=="sd[a-z]*[0-9]*|mmcblk[0-9]*p[0-9]*|nvme[0-9]*n[0-9]*p[0-9]*", ENV{ID_FS_TYPE}=="ext4", ATTR{../queue/scheduler}="mq-deadline"
      '';
    };

    # disk(ssd) optimization
    # https://kokada.dev/blog/an-unordered-list-of-hidden-gems-inside-nixos/
    services.fstrim.enable = true;

    # irqbalance for multi cpu systems
    # https://kokada.dev/blog/an-unordered-list-of-hidden-gems-inside-nixos/
    services.irqbalance.enable = true;

    # IPC performance improvement
    # https://kokada.dev/blog/an-unordered-list-of-hidden-gems-inside-nixos/
    services.dbus.implementation = "broker";

    # journal
    services.journald = {
      extraConfig = ''
        SystemMaxUse=200M
      '';
    };

    # Disable tty to prohibit console login.
    systemd.services =
      let
        ttys = [
          "tty1"
          "tty2"
          "tty3"
          "tty4"
          "tty5"
          "tty6"
        ];
      in
      lib.mkMerge (
        builtins.map (tty: {
          "getty@${tty}".enable = lib.mkForce cfg.headless;
          "autovt@${tty}".enable = lib.mkForce cfg.headless;
        }) ttys
      );

    # Experimental
    # kernel parameter for tuning performance
    # https://wiki.archlinux.jp/index.php/Sysctl
    # https://github.com/cleverca22/nixos-configs/blob/master/nas.nix
    # https://gist.github.com/jedi4ever/903751
    boot.kernelModules = [ "tcp_bbr" ];
    boot.kernel.sysctl = lib.my.flatten "_flattenIgnore" {
      # generic
      # https://gist.github.com/voluntas/bc54c60aaa7ad6856e6f6a928b79ab6c
      fs.file-max = 2097152;
      # network
      # https://meetup-jp.toast.com/1505
      # https://wiki.archlinux.jp/index.php/Sysctl#.E3.83.91.E3.83.95.E3.82.A9.E3.83.BC.E3.83.9E.E3.83.B3.E3.82.B9.E3.82.92.E5.90.91.E4.B8.8A.E3.81.95.E3.81.9B.E3.82.8B
      net = {
        ipv4 = {
          tcp_mem = "65536 131072 262144";
          udp_mem = "65536 131072 262144";
          tcp_rmem = "8192 87380 16777216";
          tcp_wmem = "8192 65536 16777216";
          udp_rmem_min = 16384;
          udp_wmem_min = 16384;
          tcp_fastopen = 3;
          tcp_congestion_control = "bbr";
        };
        core = {
          rmem_default = 16777216;
          wmem_default = 16777216;
          rmem_max = 16777216;
          wmem_max = 16777216;
          optmem_max = 40960;
          default_qdisc = "cake";
        };
      };
    };
  };

  # Minimize: https://discourse.nixos.org/t/how-to-have-a-minimal-nixos/22652/4
  # And modulesPath: https://discourse.nixos.org/t/how-to-import-a-nixpkgs-profile-using-nixos-configuration-flake/21399/2
  imports = [
    (modulesPath + "/profiles/minimal.nix")
    (modulesPath + "/profiles/hardened.nix")

    (modulesPath + "/profiles/headless.nix")

    ./minimal.nix
    ./memory-management.nix
    ./ntp.nix
  ];
  disabledModules = [
    (modulesPath + "/profiles/all-hardware.nix")
    (modulesPath + "/profiles/base.nix")
  ];
}
