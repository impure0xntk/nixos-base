{ config, pkgs, lib, ... }:
let
  cfg = config.my.system.chat;

  # https://matrix-construct.github.io/tuwunel/deploying/nixos.html#jemalloc-and-hardened-profile
/*   package = pkgs.unstable.matrix-tuwunel.override {
    enableJemalloc = false;
  }; */
  package = pkgs.unstable.matrix-tuwunel;
in
{
  options.my.system.chat = {
    enable = lib.mkEnableOption "Enable Matrix Conduit server";
    serverName = lib.mkOption {
      type = lib.types.str;
      description = "The server name for Matrix Conduit.";
      default = "";
    };
    host = lib.mkOption {
      type = lib.types.str;
      description = "The host for Matrix Conduit.";
      default = "127.0.0.1";
    };
    port = lib.mkOption {
      type = lib.types.port;
      description = "The port for Matrix Conduit.";
      default = 6167;
    };
    extraGlobalSettings = lib.mkOption {
      type = lib.types.attrs;
      description = "Extra settings for Matrix Conduit.";
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    services.matrix-tuwunel = {
      enable = true;
      package = package;
      settings.global = {
        address = [ cfg.host ];
        port = [ cfg.port ];
        server_name = cfg.serverName;
      } // cfg.extraGlobalSettings;
    };
  };
}