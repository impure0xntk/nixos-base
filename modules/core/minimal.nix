{ lib, modulesPath, ... }:
{
  config = {
    # Minimize: https://discourse.nixos.org/t/how-to-have-a-minimal-nixos/22652/4
    # includeDefaultModules is false by default, to use vm, set true.
    boot.initrd.includeDefaultModules = lib.mkDefault false; # only add strictly necessary modules
    # boot.initrd.kernelModules = [ "ext4" ... ];
    services.printing.enable = false;
    services.speechd.enable = false; # https://github.com/NixOS/nixpkgs/pull/330440
    # Additional, not covered by minimal.nix
    # inspire: https://discourse.nixos.org/t/removing-system-packages/24995/3
    programs.nano.enable = false;
    # Minimize related to perlless
    system.tools.nixos-generate-config.enable = false;
  };

  # modulesPath: https://discourse.nixos.org/t/how-to-import-a-nixpkgs-profile-using-nixos-configuration-flake/21399/2
  imports = [
    (modulesPath + "/profiles/minimal.nix")
  ];
}
