{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-bitcoin-maintainer-tools = {
      url = "github:rust-bitcoin/rust-bitcoin-maintainer-tools";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, disko, nixvim, home-manager, rust-bitcoin-maintainer-tools, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      vars = import ./vars.nix;
      rbmtSrc = pkgs.fetchFromGitHub {
        owner = "rust-bitcoin";
        repo = "rust-bitcoin-maintainer-tools";
        rev = "master";
        hash = "sha256-910879f53f3b5a9375ca0b82df1c436e63d4113faf35420305cc31882879cdfb";
      };
      rbmt = pkgs.rustPlatform.buildRustPackage {
        pname = "cargo-rbmt";
        version = "0.1.0";
        src = rbmtSrc + "/cargo-rbmt";
        cargoLock = null;
        cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      };
    in
    {
      nixosConfigurations."2140" = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit pkgs rbmt; username = vars.username; };
            home-manager.users.${vars.username} = {
              imports = [
                nixvim.homeManagerModules.nixvim
                ./home-manager/home.nix
              ];
            };
          }
          ./configuration.nix
          {
            _module.args = {
              username = vars.username;
              sshKey = vars.sshKey;
            };
          }
        ];
      };
      formatter.${system} = pkgs.nixpkgs-fmt;
    };
}
