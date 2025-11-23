{ config, lib, ... }:
let
  cfg = config.my.system.certs;
in
{
  options.my.system.certs = {
    enable = lib.mkEnableOption "Whether to enable system certificates management.";
    defaultEmail = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Email address for certificate registration.";
      default = null;
    };
    certs = lib.mkOption {
      type = lib.types.nullOr lib.types.attrs;
      description = "Certificate settings per domain.";
      default = null;
      example = {
        "example.com" = {
          dnsProvider = "cloudflare";
          environmentFile = "/etc/cert-dns-provider.env";
        };
      };
    };
  };
  config = lib.mkIf config.my.system.certs.enable {
    security.acme = {
      defaults = {
        email = cfg.defaultEmail;
        enableDebugLogs = true;
      };
      acceptTerms = true;
      certs = cfg.certs;
    };
  };
}
