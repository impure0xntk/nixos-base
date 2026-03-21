{ config, lib, pkgs, ... }:
let
  cfg = config.my.system.ai.local;
  cfgAi = config.my.system.ai;
in
{
  options = {
    my.system.ai.local = {
      enable = lib.mkEnableOption "Whether to enable local service.";
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.pure-unstable.ollama;
        description = "Ollama package to use.";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 11434;
        description = "Port on which Ollama will listen.";
      };
      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Host interface on which Ollama will listen.";
      };
      loadModels = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of model names to pull at startup.";
      };
      environmentVariables = lib.mkOption {
        type = lib.types.attributeSetOf lib.types.str;
        default = { };
        description = "Environment variables to pass to the Ollama service.";
      };
    };
  };

  config = lib.mkIf (cfgAi.enable && cfg.enable) {
    services.ollama = {
      enable = true;
      package = cfg.package;
      port = cfg.port;
      host = cfg.host;
      loadModels = cfg.loadModels;
      syncModels = true;
      environmentVariables = lib.attrsets.override (
        {
          # Default models directory (if not set in home, we use the home directory for models)
          OLLAMA_MODELS = "${cfg.home}/models";
          # Default parallelism and keep-alive
          OLLAMA_NUM_PARALLEL = "1";
          OLLAMA_KEEP_ALIVE = "1h";
        }
        // # https://blog.peddals.com/ollama-vram-fine-tune-with-kv-cache/
        (
          if lib.any (m: lib.hasInfix "gemma3" m) cfg.loadModels then
            {
              # For gemma3
              OLLAMA_FLASH_ATTENTION = "0";
              OLLAMA_KV_CACHE_TYPE = "f16";
            }
          else
            {
              # General
              OLLAMA_FLASH_ATTENTION = "1";
              OLLAMA_KV_CACHE_TYPE = "q8_0";
            }
        )
        cfg.environmentVariables
      );
    };
  };
}