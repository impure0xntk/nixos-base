{ config, pkgs, lib,
... }:
{
  # Set platform type for other modules.
  # This modules may be imported from other platform,
  # so defines as default.
  my.system.platform.type = lib.mkDefault "vm";

  powerManagement.enable = false;

  hardware.bluetooth.enable = false;
  boot.blacklistedKernelModules = [ "btusb" ]; # https://discourse.nixos.org/t/how-to-disable-bluetooth/9483

  # USB. https://www.reddit.com/r/NixOS/comments/185f0x4/how_to_mount_a_usb_drive
  services.gvfs.enable = false;
  services.udisks2.enable = false;

  # Disable initrd.systemd to avoid hanging by "Applying Kernel Variables"
  boot.initrd.systemd.enable = false;
}
