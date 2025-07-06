
{ pkgs, lib, system, self, }:

(lib.nixosSystem {
  inherit system;
  modules = [
    self.nixosModules.mySystemModules
    self.nixosModules.mySystemPlatform.native-linux
    {
      system.build.myCheck = pkgs.runCommand "check" {} ''
        echo "Check passed: $MY_VAR" > $out
      '';
    }
  ];
}).config.system.build.toplevel