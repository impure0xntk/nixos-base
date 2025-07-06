{ config, pkgs, lib, ... }:
let
  cfg = config.my.system.documentation;
in {
  options.my.system.documentation = {
    enable = lib.mkEnableOption "Whether to enable documentation.";
    port = lib.mkOption {
      type = lib.types.port;
      description = "Port for LanguageTool server.";
      default = 18181;
    };
    host = lib.mkOption {
      type = lib.types.str;
      description = "hostname for LanguageTool server";
      default = config.networking.hostName;
    };
    jre = lib.mkOption {
      type = lib.types.package;
      description = "JRE package for LanguageTool.";
      default = pkgs.zulu24;
    };
  };

  config = lib.mkIf cfg.enable {
    boot.enableContainers = true;
    containers.languagetool = {
      autoStart = true;

      config = {config, pkgs, lib, ...}: {
        imports = [ ../core/minimal.nix ];
        system.stateVersion = config.system.nixos.release;

        services.journald.extraConfig = ''
          SystemMaxUse=100M
        '';

        services.languagetool = {
          enable = true;
          package = pkgs.languagetool.override {jre = cfg.jre;};
          port = cfg.port;
          jrePackage = cfg.jre;
        };
      };
    };
  };
}
