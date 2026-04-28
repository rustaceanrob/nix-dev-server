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

  outputs = { nixpkgs, disko, nixvim, home-manager, rust-bitcoin-maintainer-tools, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      vars = import ./vars.nix;
      rbmt = pkgs.rustPlatform.buildRustPackage {
        pname = "cargo-rbmt";
        version = "0.1.0";
        src = rust-bitcoin-maintainer-tools + "/cargo-rbmt";
        cargoLock = null;
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
      packages.${system} = {
        inherit rbmt;
      };
    };
}
