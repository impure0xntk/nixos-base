{
  nixpkgs,
  pkgs,
  lib,
  system,
  self,
}:

(nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit lib; };
  modules = [
    self.nixosModules.${system}.mySystemModules
    self.nixosModules.${system}.mySystemPlatform.wsl
    ({config, ...}: {
      users = {
        users = {
          # The first is default user.
          nixos = {
            password = "foobar";
            group = "nixos";
            extraGroups = [ "wheel" ];
            isNormalUser = true;
          };
        };
        groups = {
          nixos = { };
        };
      };
      my.system.users = {
        adminUser = "nixos";
        # devUsers = ["nixos"];
      };
      # home-manager.users.nixos.home.stateVersion = config.system.stateVersion;
      my.system.worklog.enable = true;
    })
  ];
}).config.system.build.toplevel
