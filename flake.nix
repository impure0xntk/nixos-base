# To make the image, do:
# $ sudo ${full path to}/nix run ".?submodules=1#nixosConfigurations.nixos-wsl-desktop.config.system.build.tarballBuilder" --impure
# On first boot: do as nix.trusted-users
# $ sudo nix-channel --update

# And build nixos + home-manager:
# $ sudo -E nixos-rebuild switch --flake ".?submodules=1#nixos-wsl-desktop" --impure
# (impure is required!)

# profiles/work is encrypted via git-crypt.
# use "git-crypt unlock <key-file>" at project root.
#
# Note: if want to lock, "git init" and "git lock -k <key-file>"
# https://github.com/AGWA/git-crypt/issues/62#issuecomment-1399340304

{
  inputs = {
    nixos.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs.url = "github:nixos/nixpkgs/release-25.05";
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.93.2-1.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sopswarden = {
      url = "github:pfassina/sopswarden";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lib = {
      url = "github:impure0xntk/nix-lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-pkgs = {
      url = "github:impure0xntk/nix-pkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixos,
      nixpkgs,
      lix-module,
      nixos-wsl,
      nix-index-database,
      sops-nix,
      sopswarden,
      nix-lib,
      nix-pkgs,
      ...
    }:
    let
      system = "x86_64-linux";
      # specialArgs = inputs;

      # Inspire: https://github.com/tiredofit/home/blob/main/flake.nix
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = nix-pkgs.nixpkgs.overlays;
      };
      lib = nixpkgs.lib.extend nix-lib.overlays.default;
    in
    {
      nixosModules.mySystemModules = {...}: lib.flatten (
        lib.forEach [ ./modules ] (path: lib.my.listDefaultNixDirs { inherit path; })
      );
      nixosModules.mySystemPlatform = {
        native-linux = {...}: {imports = [./platform/native-linux];};
        virtualbox-guest = {...}: {imports = [./platform/virtualbox-guest];};
        vm = {...}: {imports = [./platform/vm];};
        wsl = {...}: {imports = [./platform/wsl];};
      };
      
      # checks.${system}.mySystemModules = import ./tests/modules {inherit pkgs lib system self;};
    };
}
