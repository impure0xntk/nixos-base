{ config, pkgs, lib,
modulesPath,
... }:
{
  imports = [
    ../native-linux
    ../vm

  ];

  # Set platform type for other modules.
  my.system.platform.type = "nspawn";

  networking.nftables.enable = lib.mkForce false; # nspawn does not support nftables.

  # From nspawn-nixos repository and image: https://github.com/tfc/nspawn-nixos

  # Installing a new system within the nspawn means that the /sbin/init script
  # just needs to be updated, as there is no bootloader.

  system.build.installBootLoader = pkgs.writeScript "install-sbin-init.sh" ''
    #!${pkgs.runtimeShell}
    ${pkgs.coreutils}/bin/ln -fs "$1/init" /sbin/init
  '';

  system.activationScripts.installInitScript = lib.mkForce ''
    ${pkgs.coreutils}/bin/ln -fs $systemConfig/init /sbin/init
  '';

  boot.isNspawnContainer = true;
  console.enable = true;
}
