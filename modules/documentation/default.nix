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
          public = true; # Important for REST API

          # https://gist.github.com/CRTified/9d996a6a7c548ca42fa3672eee95da92
          allowOrigin = ""; # To allow access from browser addons
          settings = {
            fasttextBinary = "${pkgs.fasttext}/bin/fasttext";
            # Optional, but highly recommended
            # Data from: https://fasttext.cc/docs/en/language-identification.html
            # 131 MB
            fasttextModel = pkgs.fetchurl {
              name = "lid.176.bin";
              url = "https://dl.fbaipublicfiles.com/fasttext/supervised-models/lid.176.bin";
              hash = "sha256-fmnsVFG8JhzHhE5J5HkqhdfwnAZ4nsgA/EpErsNidk4=";
            };
            # Data from:
            # https://languagetool.org/download/archive/word2vec/
            word2vecModel = pkgs.linkFarm "word2vec"
              (builtins.mapAttrs (_: v: pkgs.fetchzip v) {
                en = { # 83M
                  url = "https://languagetool.org/download/archive/word2vec/en.zip";
                  hash = "sha256-PAR0E8qxHBfkHYLJQH3hiuGMuyNF4cw9UbQeXVbau/A=";
                };
              });
          };
        };
      };
    };
  };
}
