{ config, lib, pkgs, ... }:
let
  cfg = config.my.system.ai.local;
  cfgAi = config.my.system.ai;
in
{
  options = {
    my.system.ai.local = {
      enable = lib.mkEnableOption "Whether to enable local service.";
      gpu = lib.mkOption {
        type = lib.types.enum [ "none" "cuda" "rocm" "vulkan" ];
        default = "none";
        description = "GPU support for local service.";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 11434;
        description = "Port on which local service will listen.";
      };
      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Host interface on which local service will listen.";
      };
      loadModels = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of model names to pull at startup.";
      };
      environmentVariables = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Environment variables to pass to the local service.";
      };
    };
  };

  config = lib.mkIf cfgAi.enable {
    services.ollama = {
      enable = cfg.enable;
      package = if cfg.gpu == "cuda" then pkgs.unstable.ollama-cuda
        else if cfg.gpu == "rocm" then pkgs.unstable.ollama-rocm
        else if cfg.gpu == "vulkan" then pkgs.unstable.ollama-vulkan
        else pkgs.unstable.ollama;
      acceleration = if cfg.gpu == "none" then null else cfg.gpu;
      port = cfg.port;
      host = cfg.host;
      loadModels = cfg.loadModels;
      syncModels = true;
      environmentVariables = (
        {
          # Default parallelism and keep-alive
          OLLAMA_NUM_PARALLEL = "2";
          OLLAMA_MAX_LOADED_MODELS = "2";
          OLLAMA_KEEP_ALIVE = "1h";

          OLLAMA_FLASH_ATTENTION = "1";
          OLLAMA_KV_CACHE_TYPE = "q8_0";
        }
        // cfg.environmentVariables
      );
    };
    systemd.services.ollama.environment = lib.optionalAttrs (config.wsl.enable) {
      LD_LIBRARY_PATH = "/usr/lib/wsl/lib";
    };
  };
}