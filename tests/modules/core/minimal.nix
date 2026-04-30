{
  pkgs,
  lib,
  system,
  self,
  ...
}:

pkgs.testers.runNixOSTest {
  name = "minimal-module-tests";

  node.specialArgs = {
    inherit lib;
  };

  nodes.machine = { config, pkgs, ... }: {
    imports = [ self.nixosModules.${system}.mySystemModules ];
    my.system.core.headless = true;
  };

  testScript = ''
    machine.start()

    # Test 1: printing disabled
    machine.fail("systemctl is-active --quiet cups.service")

    # Test 2: speechd disabled
    machine.fail("systemctl is-active --quiet speech-dispatcher.service")

    # Test 3: nano disabled
    machine.fail("which nano")

    # Test 4: nixos-generate-config disabled
    machine.fail("which nixos-generate-config")

    # Test 5: system boots successfully
    machine.succeed("systemctl is-system-running --wait --timeout=30")
  '';
}
