{ config, lib, allowedUsers, ... }:
{
  # Application container.
  # To control without sudo, add user to group "docker".
  users.groups.docker.members = lib.optionals
    (config.virtualisation.docker.enable
      || !config.virtualisation.docker.rootless.enable) allowedUsers;
  virtualisation.docker = {
      # rootless = { # rootless docker cannot use overlay networks.
      #   enable = true;
      #   setSocketVariable = true; # set $DOCKER_HOST
      # };
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };
}
