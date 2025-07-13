{
  pkgs,
  lib,
  system,
  self,
}:

(lib.nixosSystem {
  inherit system;
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
    })
  ];
}).config.system.build.toplevel
