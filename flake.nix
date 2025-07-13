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
    flake-utils.url = "github:numtide/flake-utils";
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.93.2-1.tar.gz";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
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
    nix-lib = {
      url = "github:impure0xntk/nix-lib";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    nix-pkgs = {
      url = "github:impure0xntk/nix-pkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachSystem
      (with flake-utils.lib.system; [ # supported systems
        x86_64-linux
        aarch64-linux
      ])
      (
        system:
        let
          # specialArgs = inputs;

          # Inspire: https://github.com/tiredofit/home/blob/main/flake.nix
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = inputs.nix-pkgs.nixpkgs.overlays;
          };
          lib = nixpkgs.lib.extend inputs.nix-lib.overlays.default;
        in
        {
          nixosModules.mySystemModules = {
            imports =
              with inputs;
              [
                lix-module.nixosModules.default # Use lix instead of nix
                nixos-wsl.nixosModules.default
                nix-index-database.nixosModules.nix-index
                home-manager.nixosModules.home-manager
                sops-nix.nixosModules.sops
              ]
              ++ (lib.flatten (lib.forEach [ ./modules ] (path: lib.my.listDefaultNixDirs { inherit path; })));
          };
          nixosModules.mySystemPlatform = {
            native-linux =
              { ... }:
              {
                imports = [ ./platform/native-linux ];
              };
            virtualbox-guest =
              { ... }:
              {
                imports = [ ./platform/virtualbox-guest ];
              };
            vm =
              { ... }:
              {
                imports = [ ./platform/vm ];
              };
            wsl =
              { ... }:
              {
                imports = [ ./platform/wsl ];
              };
          };

          checks.mySystemModules = import ./tests/modules {
            inherit
              pkgs
              lib
              system
              self
              ;
          };
        }
      );
}
