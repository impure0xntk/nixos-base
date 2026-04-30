{
  pkgs,
  lib,
  system,
  self,
  ...
}:

pkgs.testers.runNixOSTest {
  name = "core-default";

  node.specialArgs = {
    inherit lib;
  };

  nodes.machine = { config, pkgs, ... }: {
    imports = [ self.nixosModules.${system}.mySystemModules ];
    my.system.core.mutableSystem = true;
  };

  testScript = ''
    machine.start()
    # nh tool is available
    machine.succeed("which nh")
    # cgroupv2
    machine.succeed("stat -fc %T /sys/fs/cgroup | grep -q cgroup2fs")

    # BBR TCP congestion control is enabled
    machine.succeed("sysctl net.ipv4.tcp_congestion_control | grep -q bbr")
  '';
}
