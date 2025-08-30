{
  description = "A simple NixOS flake";

  inputs = {
    # NixOS official package source, using the nixos-25.05 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/x86_64-linux";

    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence/home-manager-v2";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix/monthly";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.systems.follows = "systems";
    };
    exchequer.url = "git+ssh://git@github.com/hannahfluch/exchequer?ref=main";
    firefox-extensions = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    shell = {
      url = "github:hannahfluch/chicken-shell";
      inputs.nixpkgs.follows = "unstable";
      inputs.systems.follows = "systems";
    };
    ccnace = {
      url = "github:inet4/ccnace";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.firefox-extensions.follows = "firefox-extensions";
    };
    stylix = {
      url = "github:nix-community/stylix/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };
    assets = {
      url = "github:hannahfluch/dotfile-assets";
      # url = "path:/home/hannah/assets";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      unstable,
      disko,
      impermanence,
      home-manager,
      fenix,
      agenix,
      exchequer,
      firefox-extensions,
      shell,
      ccnace,
      stylix,
      assets,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = pkgsExternal.extend (_: prev: import ./pkgs prev);

      pkgsExternal = import nixpkgs {
        inherit system overlays;
        config.allowUnfreePredicate =
          pkg:
          builtins.elem (pkgs.lib.getName pkg) [
            "datagrip"
            "idea-ultimate"
            "geogebra"
            "obsidian"
            "ciscoPacketTracer8"
            "binaryninja-free"
            "volatility3"
            "burpsuite"
            "steam-unwrapped"
          ];
      };

      overlays = [
        fenix.overlays.default
      ];
      extra = {
        agenix = agenix.packages.${system}.default;
        extensions = firefox-extensions.packages.${system};
        shell = shell.packages.${system}.default;
        ccnace = ccnace.packages.${system}.default;
      };

      unstablePkgs = import unstable {
        inherit system;
        # todo: networkminer somehow requires this (???)
        config.permittedInsecurePackages = [
          "dotnet-sdk-6.0.428"
          "dotnet-runtime-6.0.36"
        ];
      };

    in
    {
      nixosConfigurations.chicken = nixpkgs.lib.nixosSystem {
        inherit system pkgs;
        modules = [
          {
            # pin system nixpkgs to the same version as the flake input
            # (don't see a way to declaratively set channels but this seems to work fine?)
            nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
          }
          # Import the previous configuration.nix we used,
          # so the old configuration file still takes effect
          ./configuration.nix
          ./hosts/lenovo-thinkpad-e14-g7.nix

          home-manager.nixosModules.home-manager
          {
            home-manager = {

              # same pkgs, overlays, ... for nixos and home-manager
              useGlobalPkgs = true;
              extraSpecialArgs = { inherit unstablePkgs extra assets; };
              users.hannah =
                { ... }:
                {
                  imports = [
                    ./home
                    ./persist/home.nix
                    impermanence.homeManagerModules.impermanence
                    agenix.homeManagerModules.default
                    exchequer.homeManagerModules.default
                    stylix.homeModules.stylix
                  ];
                };
            };
          }

          disko.nixosModules.disko
          ./disko/disko-config.nix

          impermanence.nixosModules.impermanence
          ./impermanence.nix

          ./persist/persist.nix
          ./persist/conf.nix

          agenix.nixosModules.default
          exchequer.nixosModules.default
        ];
      };
      nixosConfigurations.hatcher = nixpkgs.lib.nixosSystem {

        modules = [
          (
            { pkgs, modulesPath, ... }:
            {
              imports = [
                (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
              ];
              networking.wireless.enable = false;
              isoImage.squashfsCompression = "zstd";

              isoImage.contents = [
                {
                  source = self;
                  target = "/source";
                }
              ];

              isoImage.storeContents = [ self.nixosConfigurations.chicken.config.system.build.toplevel ];

              environment.systemPackages = [
                disko.packages.x86_64-linux.disko-install

                (pkgs.writeShellScriptBin "install-with-disko" (builtins.readFile ./scripts/install-with-disko.sh))
              ];
            }
          )
          ./hatcher.nix
          ./hosts/lenovo-thinkpad-e14-g7.nix
        ];
      };
    };
}
