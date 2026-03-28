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
      settings = cfg.settings;
    };
  };
}
