{
  description = "Motoko Bootcamp 2023 enrollment";

  inputs = {
    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixos-22.11";
      flake = true;
    };

    nixpkgs-unstable = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixos-unstable";
      flake = true;
    };

    devenv = {
      type = "github";
      owner = "cachix";
      repo = "devenv";
      ref = "main";
      flake = true;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      type = "github";
      owner = "nix-community";
      repo = "fenix";
      ref = "main";
      flake = true;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    devenv,
    fenix,
    ...
  } @ inputs: let
    inherit (self) outputs;

    supportedSystems = [
      "x86_64-linux"
    ];

    rustTargets = [
      "wasm32-unknown-unknown"
    ];

    forAllSystems = f:
      builtins.listToAttrs (map (buildPlatform: {
          name = buildPlatform;
          value = builtins.listToAttrs (map (hostPlatform: {
              name = hostPlatform;
              value = f buildPlatform hostPlatform;
            })
            supportedSystems);
        })
        supportedSystems);

    forAllRustTargets = f:
      builtins.listToAttrs (map (rustTarget: {
          name = rustTarget;
          value = builtins.listToAttrs (map (rustTarget: {
              name = rustTarget;
              value = f rustTarget.latest.rust-std;
            })
            rustTargets);
        })
        rustTargets);

    pkgsImportCrossSystem = pkgChannel: buildPlatform: hostPlatform:
      import pkgChannel {
        system = buildPlatform;
        overlays = [];
        config = {
          allowUnfree = true;
          allowUnfreePredicate = _: true;
        };
        crossSystem =
          if buildPlatform == hostPlatform
          then null
          else {
            config = hostPlatform;
          };
      };

    flattenPackages = systems:
      builtins.foldl' (acc: system:
        builtins.foldl' (
          innerAcc: hostPlatform:
            innerAcc // {"${system}.${hostPlatform}" = systems.${system}.${hostPlatform};}
        )
        acc (builtins.attrNames systems.${system})) {} (builtins.attrNames systems);
  in {
    ###############
    ## Packages
    ###############

    packages = flattenPackages (forAllSystems (buildPlatform: hostPlatform: let
      # Build Platform
      system = buildPlatform;
      pkgs = pkgsImportCrossSystem nixpkgs buildPlatform buildPlatform;
      pkgsUnstable = pkgsImportCrossSystem nixpkgs-unstable buildPlatform buildPlatform;

      # Host Platform
      crossPkgs = pkgsImportCrossSystem nixpkgs buildPlatform hostPlatform;
      crossPkgsUnstable = pkgsImportCrossSystem nixpkgs-unstable buildPlatform hostPlatform;

      # Rust
      rustTarget = "wasm32-unknown-unknown";
      rustProfile = fenix.packages.${system}.complete;
      rustToolchain = rustProfile;
      #rustToolchain = with rustProfile; combine [
      #complete.cargo
      #complete.rustc
      #complete.clippy
      #complete.rust-src
      #complete.rustfmt
      #targets.\${rustTarget}.latest.rust-std
      #];
      rustPlatform = pkgs.makeRustPlatform {
        cargo = rustToolchain;
        rustc = rustToolchain;
      };
    in {
      #hello = import ./nix/packages/hello {
      #  inherit pkgs;
      #  inherit crossPkgs;
      #  inherit rustPlatform;
      #};
    }));

    # Set the default package for the current system.
    #defaultPackage = builtins.listToAttrs (map (system: {
    #    name = system;
    #    value = self.packages."${system}.${system}".hello;
    #  })
    #  supportedSystems);

    ###############
    ## DevShells
    ###############

    devShells = flattenPackages (forAllSystems (buildPlatform: hostPlatform: let
      # Build Platform
      system = buildPlatform;
      pkgs = pkgsImportCrossSystem nixpkgs buildPlatform buildPlatform;
      pkgsUnstable = pkgsImportCrossSystem nixpkgs-unstable buildPlatform buildPlatform;

      # Host Platform
      crossPkgs = pkgsImportCrossSystem nixpkgs buildPlatform hostPlatform;
      crossPkgsUnstable = pkgsImportCrossSystem nixpkgs-unstable buildPlatform hostPlatform;

      # Rust
      #rustToolchainTargets = forAllRustTargets (rustTarget);
      rustTarget = "wasm32-unknown-unknown";
      rustToolchain = with fenix.packages.${system};
        combine [
          complete.cargo
          complete.rustc
          complete.clippy
          complete.rust-src
          complete.rustfmt
          targets.${rustTarget}.latest.rust-std
          #rustToolchainTargets
        ];
    in {
      devenv = import ./nix/devshells/devenv {
        inherit inputs;
        inherit system;
        inherit pkgs;
        inherit crossPkgs;
        inherit rustToolchain;
      };
    }));

    # Set the default devshell to the one for the current system.
    devShell = builtins.listToAttrs (map (system: {
        name = system;
        value = self.devShells."${system}.${system}".devenv;
      })
      supportedSystems);
  };
}
