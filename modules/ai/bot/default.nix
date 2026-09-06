{ config, pkgs, lib, ... }:
let
  cfg = config.my.system.ai.bot;
  officialOptions = "${pkgs.fetchFromGitHub {
    owner = "zeroclaw-labs";
    repo = "zeroclaw";
    rev = "c107d55a51757b8a0ce726d123418b37b94db900"; # 2026/09/06
    hash = "sha256-7jfu6Woz8/odlBsf1kpE0hrKjM278UoBqCzX66MooPQ=";
  }}/nix/module.nix";
in {
  imports = [ officialOptions ];

  options.my.system.ai.bot = {
    enable = lib.mkEnableOption "Whether to enable bot.";
    instances = lib.mkOption {
      type = lib.types.attrs;
      description = "instance settings. see https://github.com/zeroclaw-labs/zeroclaw/tree/master/nix";
    };
  };

  config = lib.mkIf cfg.enable {
    services.zeroclaw.instances = cfg.instances;
  };
}
