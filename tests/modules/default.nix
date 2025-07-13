
{ pkgs, lib, system, self, }:

(lib.nixosSystem {
  inherit system;
  modules = [
    self.nixosModules.mySystemModules
    self.nixosModules.mySystemPlatform.wsl
    {
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
      my.system.users.adminUser = "nixos";
    }
  ];
}).config.system.build.toplevel