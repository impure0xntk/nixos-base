{ config, pkgs, lib, ... }:
let
  immutable = (! config.my.system.core.mutableSystem);
in {
  # Set machine type for other modules.
  # This modules may be imported from other platform,
  # so defines as default.
  my.system.platform.type = lib.mkDefault "native-linux";

  boot = {
    # kernelPackages = let
    #   linuxZenWMuQSS = pkgs.linuxPackagesFor (pkgs.linuxPackages_zen.kernel.override {
    #     structuredExtraConfig = with lib.kernel; {
    #       SCHED_MUQSS = yes;
    #     };
    #     ignoreConfigErrors = true;
    #   }
    #   );
    # in linuxZenWMuQSS;
    kernelPackages = pkgs.linuxPackages_zen;

    loader.timeout = lib.mkIf immutable 0;
    loader.grub.configurationLimit = lib.mkIf immutable 1; # https://discourse.nixos.org/t/how-to-disable-boot-nixos-generation-selection-menu/33092/6
    loader.grub.splashImage = lib.mkIf immutable null;
  };
}
