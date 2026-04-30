{
  pkgs,
  lib,
  system,
  self,
  ...
}:

pkgs.testers.runNixOSTest {
  name = "ntp-module-tests";

  node.specialArgs = {
    inherit lib;
  };

  nodes.machine = { config, pkgs, ... }: {
    imports = [ self.nixosModules.${system}.mySystemModules ];
    my.system.core.headless = true;
  };

  testScript = ''
    machine.start()

    # chronyd service active
    machine.succeed("systemctl is-active --quiet chronyd.service")

    # chronyc binary exists
    machine.succeed("which chronyc")

    # chronyd binary exists
    machine.succeed("which chronyd")

    # NTS enabled
    machine.succeed("chronyc ntsdata | grep -q 'NTS enabled'")

    # cloudflare NTP server configured
    machine.succeed("chronyc sources | grep -q 'time.cloudflare.com'")

    # timesyncd disabled
    machine.fail("systemctl is-active --quiet systemd-timesyncd.service")

    # iburst option
    machine.succeed("grep -q 'iburst' /etc/chrony.conf")

    # rtcfile configured
    machine.succeed("grep -q 'rtcfile' /etc/chrony.conf")

    # autotrim threshold
    machine.succeed("grep -q 'autotrim' /etc/chrony.conf")

    # systemd-timesyncd disabled
    machine.fail("systemctl is-active --quiet systemd-timesyncd.service")
  '';
}