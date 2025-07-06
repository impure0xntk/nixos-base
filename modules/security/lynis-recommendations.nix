{ config, pkgs, lib, ... }:
let
in
{
  config = {
    # Kernel Hardening
    boot.kernel.sysctl = {
      "fs.suid_dumpable" = 0;
      "kernel.ctrl-alt-del" = 0;
      "kernel.dmesg_restrict" = 1;
      "kernel.kptr_restrict" = lib.mkForce 2;
      "kernel.perf_event_paranoid" = 3;
      "kernel.unprivileged_bpf_disabled" = 1;

      "net.ipv4.conf.all.forwarding" = 0;
    };
  };
}
