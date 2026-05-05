{
  description = "My Flakes";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      #url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    minegrub-theme.url = "github:Lxtharia/minegrub-theme";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    prismlauncher = {
      url = "github:Diegiwg/PrismLauncher-Cracked";
    };
    nixcord.url = "github:FlameFlag/nixcord";
    librewolf-nix = {
      url = "github:pierrot-lc/librewolf-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      #url = "github:danth/stylix";
      #url = "github:danth/stylix/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-code.url = "github:sadjow/claude-code-nix";
  };

  outputs = inputs@{ 
    self, 
    nixpkgs, 
    home-manager, 
    nix-flatpak, 
    prismlauncher, 
    librewolf-nix,  
    nixvim,
    stylix,
    claude-code,
    ... 
  }:
  let
    system = "x86_64-linux";
  in {
    nixosConfigurations.MB-PC = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        stylix.nixosModules.stylix
        ./configuration.nix
	#home-manager.nixosModules.home-manager
        home-manager.nixosModules.default
	{
	  nixpkgs.overlays = [ claude-code.overlays.default ];
          home-manager = {
            useGlobalPkgs = true;
	    useUserPackages = true;
	    users.mbyte = import ./home.nix;
	    backupFileExtension = "backup";
            extraSpecialArgs = { inherit inputs system; };
	  };
	}

	inputs.minegrub-theme.nixosModules.default
	#./stylix.nix
        (
          { pkgs, ... }:
          {
            environment.systemPackages = [ prismlauncher.packages.${pkgs.system}.prismlauncher ];
          }
        )
      ];
    };
  };
}
