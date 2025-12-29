{ config, pkgs, lib, ... }:
let
  cfg = config.my.system.knowledgebase;
in {
  options.my.system.knowledgebase = {
    enable = lib.mkEnableOption "Whether to enable knowledgebase.";
    host = lib.mkOption {
      type = lib.types.str;
      description = "Host address for knowledgebase server access.";
      default = "127.0.0.1";
    };
    port = lib.mkOption {
      type = lib.types.port;
      description = "Port for knowledgebase server.";
      default = 8000;
    };
  };

  config = lib.mkIf cfg.enable {
    services.outline = {
      enable = true;
      package = pkgs.pure-unstable.outline;
      port = cfg.port;
      publicUrl = "http://${cfg.host}:${toString cfg.port}";
      forceHttps = false;
      storage = {
        storageType = "local";
      };
    };
  };
}
