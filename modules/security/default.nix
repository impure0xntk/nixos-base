{ config, pkgs, lib, ... }:
{
  imports = [
    ./STIG.nix
    ./lynis-recommendations.nix
    ./clamav
  ];
  assertions = [
    {
      assertion = !config.security.sudo.enable;
      message = "Use sudo-rs instead of sudo, and set nothing to security.sudo";
    }
  ];

  security.apparmor.enable = lib.mkDefault true;

  # Replace sudo to sudo-rs, and only allow wheel group
  security.sudo.enable = false;
  security.sudo-rs = {
    enable = true;
    execWheelOnly = true;
  };

  # Disable coredump
  systemd.coredump.enable = lib.mkDefault false;
  security.pam.loginLimits = lib.optionals (!config.systemd.coredump.enable) [
    {
      domain = "*";
      item = "core";
      type = "soft";
      value = "0";
    }
  ];
  # Kernel hardening
  boot.kernel.sysctl = lib.my.flatten "_flattenIgnore" {
    vm = {
      mmap_rnd_bits = 32;
      mmap_rnd_compat_bits = 16;
    };
    # Disable bpf via profiles/hardened.nix
    net.core.bpf_jit_harden = 2;

    # hardened profile does not support
    net.tcp_rfc1337 = 1;

    fs = {
      protected_fifos = 2;
      protected_regular = 2;
      protected_hardlinks = 1;
      protected_symlinks = 1;
    };
  };
}
