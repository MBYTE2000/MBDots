{
  description = "MBYTE NixOS — dendritic-style config (host: nixos)";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    minegrub-theme.url = "github:Lxtharia/minegrub-theme";
    nix-flatpak.url    = "github:gmodena/nix-flatpak/?ref=latest";

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    prismlauncher.url  = "github:Diegiwg/PrismLauncher-Cracked";
    freesmlauncher.url = "github:FreesmTeam/FreesmLauncher";
    nixcord.url        = "github:FlameFlag/nixcord";

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code.url = "github:sadjow/claude-code-nix";
    vintagestory.url = "github:MBYTE2000/VintageStoryFplaysu";

    #comfyui-nix.url = "github:utensils/comfyui-nix";
    deepseek-harness.url = "github:Moraxyc/deepseek-harness.nix";
  };

  outputs = inputs@{
    self,
    nixpkgs,
    home-manager,
    stylix,
    claude-code,
    minegrub-theme,
    #comfyui-nix,
    deepseek-harness,
    ...
  }:
  let
    system = "x86_64-linux";
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        # Тема и Stylix
        stylix.nixosModules.stylix

        # Опциональные внешние модули
        #comfyui-nix.nixosModules.default
        deepseek-harness.nixosModules.default
        minegrub-theme.nixosModules.default

        # Хост
        ./hosts/nixos

        # Home-manager + оверлеи
        home-manager.nixosModules.default
        {
          nixpkgs.overlays = [ claude-code.overlays.default ];
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.mbyte = {
              imports = [ ./home ];
            };
            backupFileExtension = "backup";
            extraSpecialArgs = { inherit inputs system; };
          };
        }
      ];
    };
  };
}
