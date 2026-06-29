{
  description = "macbookair: nix-darwin + home-manager system config";

  inputs = {
    # Stable macOS-tested channels; bump the three together each release.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Determinate Nix module: manages the daemon, caches, and GC.
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      determinate,
    }:
    {
      darwinConfigurations."macbookair" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        modules = [
          determinate.darwinModules.default
          ./darwin.nix
          ./homebrew.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-bak";
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.gm = import ./home.nix;

            users.users.gm = {
              name = "gm";
              home = "/Users/gm";
            };
          }
        ];
      };

      formatter.aarch64-darwin =
        let
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        in
        pkgs.writeShellApplication {
          name = "fmt";
          runtimeInputs = [ pkgs.nixfmt-rfc-style ];
          text = "find . -name '*.nix' -not -path './.git/*' -exec nixfmt {} +";
        };
    };
}
