{ config, pkgs, lib, ... }:
let
  cfg = config.my.system.bookmark;
in {
  options.my.system.bookmark = {
    enable = lib.mkEnableOption "Whether to enable bookmark daemon.";
    host = lib.mkOption {
      type = lib.types.str;
      description = "Host for bookmark server.";
      default = "127.0.0.1";
    };
    port = lib.mkOption {
      type = lib.types.port;
      description = "Port for bookmark server.";
      default = 15050;
    };
    extraEnvironment = lib.mkOption {
      type = lib.types.attrs;
      description = "extraEnvironment";
      default = {};
    };
    inference = {
      enable = lib.mkEnableOption "Whether to enable bookmark inference.";
      url = lib.mkOption {
        type = lib.types.str;
        description = "URL of OPENAI API Endpoint for inference";
        default = "http://127.0.0.1:4000";
      };
      textModel = lib.mkOption {
        type = lib.types.str;
        description = "Model name for inference";
        default = "not found";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.karakeep = {
      enable = true;
      package = pkgs.pure-unstable.karakeep;
      browser.exe = lib.getExe pkgs.pure-unstable.ungoogled-chromium;
      extraEnvironment = {
        PORT = toString cfg.port;
        # DISABLE_SIGNUPS = "true";
        DISABLE_NEW_RELEASE_CHECK = "true";
      } // (lib.optionalAttrs cfg.inference.enable rec {
        OPENAI_API_KEY= "dummy";
        OPENAI_BASE_URL = cfg.inference.url;
        INFERENCE_TEXT_MODEL = cfg.inference.textModel;
        INFERENCE_IMAGE_MODEL = INFERENCE_TEXT_MODEL;
        EMBEDDING_TEXT_MODEL = INFERENCE_TEXT_MODEL;
      }) // cfg.extraEnvironment;
    };
  };
}
