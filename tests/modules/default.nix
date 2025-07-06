
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
      system.build.myCheck = pkgs.runCommand "check" {} ''
        echo "Check passed: $MY_VAR" > $out
      '';
    }
  ];
}).config.system.build.toplevel