# User should select own desktop environment via home-manager.
# Thus, this modules provide only minimal programs for desktop.
{lib, ...}:
{
  imports = (lib.my.listDirs {path = ./.;});
}
