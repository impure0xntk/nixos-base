{ config, lib, allowedUsers, ... }:
let
in {
  # System container.
  # To control without sudo, add user to group "docker".
  users.groups.incus.members = lib.optionals
    (config.virtualisation.docker.enable) allowedUsers;
  virtualisation.incus = {
    preseed = { # may need to reboot.
      networks = [
        {
          config = {
            "ipv4.address" = "10.0.100.1/24";
            "ipv4.nat" = "true";
            "ipv6.address" = "none";
          };
          name = "incusbr0";
          type = "bridge";
        }
      ];
      profiles = [
        {
          devices = {
            eth0 = {
              name = "eth0";
              network = "incusbr0";
              type = "nic";
            };
            root = {
              path = "/";
              pool = "default";
              size = "35GiB";
              type = "disk";
            };
          };
          name = "default";
        }
      ];
      storage_pools = [
        {
          config.source = "/var/lib/incus/storage-pools/default";
          driver = "dir";
          name = "default";
        }
      ];
    };
  };
}
