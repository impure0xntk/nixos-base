# How to install community nodes:
# * Follow https://docs.n8n.io/integrations/community-nodes/installation/manual-install/
# * Note: cannot install from GUI, (and some nodes cannot install from nix derivation and N8N_CUSTOM_EXTENSIONS)
{ config, pkgs, lib, ... }:
let
  cfg = config.my.system.workflow;

  extensionPaths = lib.concatStringsSep ";"
    (lib.forEach cfg.extensions (ext: "${ext}/lib/node_modules"));
in {
  options.my.system.workflow = {
    enable = lib.mkEnableOption "Whether to enable workflow daemon.";
    host = lib.mkOption {
      type = lib.types.str;
      description = "Host for workflow server.";
      default = "127.0.0.1";
    };
    port = lib.mkOption {
      type = lib.types.port;
      description = "Port for workflow server.";
      default = 5678;
    };
    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      description = "List of workflow extensions to install. e.g. pkgs.buildNpmPackage...";
      default = [
        (pkgs.buildNpmPackage {
          pname = "n8n-nodes-vikunja";
          version = "0.3.0";
          src = pkgs.fetchFromGitHub {
            owner = "go-vikunja";
            repo = "n8n-vikunja-nodes";
            rev = "170e9c0d34aee2d0728ab1128ef7f30f65b35ab2"; # 12/16/2025
            hash = "sha256-GpfgDHhTzP7Mo8otG7nt9ieec15qW4onXgd/XAw3XoI=";
          };
          patches = [(pkgs.writeText "disable-eslint-plugin-to-avoid-pnpm-only-error" ''
diff --git a/package.json b/package.json
index 838fc8a..67bcfe0 100644
--- a/package.json
+++ b/package.json
@@ -41,3 +41,2 @@
     "@typescript-eslint/parser": "~8.50.0",
-    "eslint-plugin-n8n-nodes-base": "^1.11.0",
     "gulp": "^5.0.0",
          '')];
          npmDepsHash = "sha256-IN+HVAE2RIfpRhrqrjK1HiooTWtGUURFz9U0ZWZ5QtQ=";
        })
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfree = true;

    services.n8n = {
      enable = true;
      environment = rec {
        N8N_HOST = cfg.host;
        N8N_PORT = toString cfg.port;
        N8N_LOG_LEVEL = "debug";
        N8N_PROTOCOL = "http";
        N8N_RUNNERS_ENABLED = "true";
        NODE_FUNCTION_ALLOW_EXTERNAL = "true";
        WEBHOOK_URL = "${N8N_PROTOCOL}://${N8N_HOST}:${N8N_PORT}";
        NODE_ENV = "production";

        N8N_CUSTOM_EXTENSIONS = extensionPaths;
      };
    };
  };
}
