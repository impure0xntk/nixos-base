# Machine config option holder.
# Each machine/* sets this value.
{ config, lib, ...}:
with lib;
with lib.types;
let
  cfg = config.my.system.platform;
  directoryNames = lib.forEach (lib.my.listDirs { path = ./../../platform;}) (v: builtins.baseNameOf v);
in {
  options.my.system.platform = {
    type = mkOption {
      type = enum directoryNames;
      description = "Platform type string. available string is the directory name of $\{repository root}/platform/*";
      example = "wsl";
      default = "native-linux";
    };
    settings = mkOption {
      type = submodule {};
      description = "Settings for the platform type. This is used to set platform specific configurations.";
      default = {};
    };

  };
  config = {
    assertions = [
      {
        assertion = lib.any (v: v == (lib.my.traceSeqWith "my.system.platform.type" cfg.type)) directoryNames;
        message = "Invalid platform type: ${cfg.type}. Select from \"${builtins.toString directoryNames}\"";
      }
    ];
  };
}
