{ config, pkgs, lib,
modulesPath,
... }:
{
  imports = [
    ../native-linux
    ../vm

    <nixpkgs/nixos/modules/virtualisation/virtualbox-image.nix>
  ];

  disabledModules = [
    # By default, modules/core imports this, but if import on virtualbox, cannot login from tty1.
    (modulesPath + "/profiles/headless.nix")
  ];

  # Set platform type for other modules.
  my.system.platform.type = "virtualbox-guest";

  # "Timed out waiting for device /dev/disk/by-label/nixos" workaround.
  boot.initrd.includeDefaultModules = true;
  # https://github.com/NixOS/nixpkgs/blob/bddcfadca904dd2e64d7d9621dc836779922f5f7/nixos/tests/virtualbox.nix#L61
  boot.initrd.kernelModules = [
    "af_packet" "vboxsf"
    "virtio" "virtio_pci" "virtio_ring" "virtio_net" "vboxguest"
  ];
}
