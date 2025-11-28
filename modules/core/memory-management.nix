{
  config,
  pkgs,
  lib,
  ...
}:
let
  avoid = lib.concatStringsSep "|" [
    "dbus-.*"
    "gpg-agent"
    "greetd"
    "ssh-agent"
    ".*qemu-system.*"
    "sshd"
    "systemd"
    "systemd-.*"
    "alacritty"
    "bash"
    "fish"
    "n?vim"
  ];

  prefer = lib.concatStringsSep "|" [
    "Web Content"
    "Isolated Web Co"
    "chrom(e|ium).*"
    "electron"
    "dotnet"
    ".*.exe"
    "java.*"
    "nix"
    "npm"
    "node"
  ];
in
{
  # swap management (disable). https://nixos.wiki/wiki/Swap
  swapDevices = lib.mkForce [ ];
  zramSwap.enable = false;
  # Use earlyoom instead of systemd-oomd for swap-free.
  systemd.oomd.enable = !config.services.earlyoom.enable;
  services.earlyoom = {
    enable = true;
    extraArgs = [
      "-g"
      "--avoid"
      "'^(${avoid})$'" # things that we want to avoid killing
      "--prefer"
      "'^(${prefer})$'" # things we want to remove fast
    ];
    # we should ideally write the logs into a designated log file; or even better, to the journal
    # for now we can hope this echo sends the log to somewhere we can observe later
    killHook = pkgs.writeShellScript "earlyoom-kill-hook" ''
      echo "Process $EARLYOOM_NAME [$EARLYOOM_PID] (\"$EARLYOOM_CMDLINE\") was killed !" \
        | ${pkgs.systemd}/bin/systemd-cat --identifier="earlyoom" -p warning
    '';
  };

  environment = {
    # Experimental

    # Cannot use scudo because some apps(startx, neovim, etc...) fails on it.
    #
    # memoryAllocator.provider = "scudo";
    # variables.SCUDO_OPTIONS = "ZeroContents=1";
    variables.SCUDO_OPTIONS = ""; # TODO: resolve

    # mimalloc: high performance memory allocator.
    # but cannot use chromium, vscode, and nvidia-ctk, so disable it... 
    #
    # memoryAllocator.provider = "mimalloc";
  };
}
