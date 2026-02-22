{
  config,
  pkgs,
  lib,
  ...
}:
let
  ntpPool = [
    # pool.ntp.org: # stratum 1, but does not have NTS support.
    "time.cloudflare.com" # stratum 3, and has NTS support
    "virginia.time.system76.com" # stratum 2, and has NTS support
    "nts.netnod.se" # stratum 1, and has NTS support
  ];
  # nixos.pool.ntp.org: does not have NTS support
  # distNtpPool = lib.forEach (lib.range 0 3) (i: "${toString i}.nixos.pool.ntp.org");
  timeServers = ntpPool;

  clientConfig = ''
    makestep 1.0 3
    driftfile /var/lib/chrony/drift
    logdir /var/log/chrony
    log measurements statistics tracking
    ntsdumpdir /var/lib/chrony
  '';
in
{
  # NTP
  # STIG V-268150: Authoritative time servers with iburst for fast initial sync
  networking.timeServers = timeServers;
  services.timesyncd.enable = lib.mkForce false; # Disable timesyncd when chronyd is enabled
  services.chrony = {
    enable = true;

    enableNTS = true;
    enableRTCTrimming = true;
    autotrimThreshold = 10;

    serverOption = "iburst";

    extraConfig = clientConfig;
  };

}
