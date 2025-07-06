{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfgDevUser = config.my.system.users.devUsers;

  devUsersAndKeys = map (
    name:
    let
      keyPair = lib.my.genSshKeyPair {
        inherit pkgs;
        name = "id_${name}_local";
      };
    in
    {
      name = name;
      priKey = keyPair.priKey;
      pubKey = keyPair.pubKey;
      priKeyName = keyPair.priKeyName;
    }
  ) cfgDevUser;

  hasGui = config.services.xserver.enable;
  # To avoid Python3 if headless.
  gitConfigured = if hasGui then pkgs.git else pkgs.gitMinimal;
in
{
  config = lib.mkIf ((builtins.length cfgDevUser) > 0) {
    # The default user will not have a password by default
    security.sudo-rs.wheelNeedsPassword = false;

    environment.systemPackages =
      with pkgs;
      [
        gitConfigured
        wget # for vscode
        home-manager
      ]
      ++ lib.optionals hasGui [
        xsel
      ];
    programs.vim = {
      enable = true;
      # package = vimTiny;
      package = pkgs.vim-tiny-customized;
      defaultEditor = true;
    };

    # The master data of shellAliases is bash's one.
    programs.fish.shellAliases = config.programs.bash.shellAliases;

    # Some IDE disallow multiple users,
    # so ready to connect SSH as Remote Development.
    # TODO: switch considering platform: WSL or not.
    home-manager.users = lib.genAttrs cfgDevUser (name: {
      home.file = builtins.listToAttrs (
        (map (attr: {
          name = ".ssh/${attr.priKeyName}";
          value = {
            # use basenameof (store path), error.
            source = attr.priKey;
            enable = true;
          };
        }) devUsersAndKeys)
      );
      programs.ssh.matchBlocks = builtins.listToAttrs (
        map (attr: {
          name = "${attr.name}-local";
          value = {
            user = attr.name;
            hostname = config.networking.hostName;
            identityFile = [ "%d/.ssh/${attr.priKeyName}" ];
          };
        }) devUsersAndKeys
      );
    });
    users.users = lib.genAttrs cfgDevUser (name: {
      openssh.authorizedKeys.keyFiles = lib.forEach devUsersAndKeys (attr: attr.pubKey);
    });
    services.openssh = {
      enable = true;
      settings.AllowUsers = cfgDevUser;
    };
  };
}
