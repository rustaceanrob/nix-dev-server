{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
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

  outputs = { nixpkgs, disko, nixvim, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      vars = import ./vars.nix;
      rbmtSrc = pkgs.fetchFromGitHub {
        owner = "rust-bitcoin";
        repo = "rust-bitcoin-maintainer-tools";
        rev = "master";
        hash = "sha256-0dp2k35m24p62xinqg3cf99v1hv3czk2nm0w4bcn030m6b1d95mv";
      };
      rbmt = pkgs.rustPlatform.buildRustPackage {
        pname = "cargo-rbmt";
        version = "0.1.0";
        src = rbmtSrc + "/cargo-rbmt";
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
