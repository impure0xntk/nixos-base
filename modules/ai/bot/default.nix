{ config, pkgs, lib, ... }:
let
  cfg = config.my.system.ai.bot;
in {
  options.my.system.ai.bot = {
    enable = lib.mkEnableOption "Whether to enable bot.";
    package = lib.mkOption {
      type = lib.types.package;
      description = "package";
      default = pkgs.zeroclaw;
    };
    settings = lib.mkOption {
      type = lib.types.attrs;
      description = "settings";
      default = {};
    };
    additionalPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [ curl gitMinimal];
      description = "Additional packages to install alongside ZeroClaw";
    };
    secretFiles = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        "/run/keys/zeroclaw-api-key" = "api_key";
        "/run/keys/telegram-token" = "channels_config.telegram.bot_token";
        "/run/keys/discord-token" = "channels_config.discord.bot_token";
        "/run/keys/slack-bot-token" = "channels_config.slack.bot_token";
        "/run/keys/brave-api-key" = "web_search.brave_api_key";
      };
      description = "Attribute set mapping file paths to TOML configuration paths. The file content will be read and injected into config.toml at the specified path. Supports nested paths using dot notation (e.g., 'channels_config.telegram.bot_token').";
    };
    extraEnvironment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = "extraEnvironment";
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    services.zeroclaw = {
      enable = true;
      package = cfg.package;
      extraEnvironment = cfg.extraEnvironment;
      additionalPackages = cfg.additionalPackages;
      secretFiles = cfg.secretFiles;
      settings = cfg.settings;
    };
  };
}
