{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-sandbox-mcp.url = "github:secbear/nix-sandbox-mcp";
  };

  outputs = { nixpkgs, nix-sandbox-mcp, ... }:
    let pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in {
      packages.x86_64-linux = {
        data-science = nix-sandbox-mcp.lib.mkSandbox {
          inherit pkgs;
          name = "data-science";
          interpreter_type = "python";
          packages = [
            (pkgs.python3.withPackages (ps: [ ps.numpy ps.pandas ps.requests ]))
          ];
        };

        nix-tools = nix-sandbox-mcp.lib.mkSandbox {
          inherit pkgs;
          name = "nix-tools";
          interpreter_type = "bash";
          packages = [ pkgs.ripgrep pkgs.fd pkgs.jq pkgs.yq-go pkgs.tree ];
        };
      };
    };
}
