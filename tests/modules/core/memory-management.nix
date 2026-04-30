{ nixpkgs, pkgs, lib, system, self }:

pkgs.testers.runNixOSTest {
  name = "core-memory-management";
  node.specialArgs = { inherit lib; };
  nodes.machine = { config, pkgs, lib, ... }: {
    imports = [ self.nixosModules.${system}.mySystemModules ];
    my.system.core.mutableSystem = true;
  };
  testScript = ''
    machine.start()

    # Check earlyoom service is active
    machine.succeed("systemctl is-active earlyoom")

    # Check earlyoom configuration
    machine.succeed("grep -q -- '--avoid' /etc/earlyoom.conf")
    machine.succeed("grep -q '--prefer' /etc/earlyoom.conf")

    # Check systemd-oomd is disabled (earlyoom is used instead)
    machine.succeed("systemctl is-enabled systemd-oomd | grep disabled")

    # Check zram-generator is disabled
    machine.succeed("systemctl is-enabled zram-generator | grep disabled")

    # Check no swap is active
    machine.succeed("swapon --show | wc -l | grep 0")

    # Check kill hook exists
    machine.succeed("test -f /etc/earlyoom/kill-hook.sh")

    # Check environment variables are set
    machine.succeed("grep -q 'SCUDO_OPTIONS' /etc/environment")
  '';
}
