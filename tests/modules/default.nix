args@{ nixpkgs, pkgs, lib, system, self }:
let
  mkTest = drvPath: import drvPath args;
in {
  core-default = mkTest ./core/default.nix;
  # core-minimal = mkTest ./core/minimal.nix;
  # core-memory-management = mkTest ./core/memory-management.nix;
  # core-ntp = mkTest ./core/ntp.nix;
}
