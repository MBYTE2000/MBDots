{ config, pkgs, inputs, system, ... }:
{
  # Базовые импорты home-manager из flake inputs.
  imports = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
    inputs.nixcord.homeModules.nixcord
    inputs.nixvim.homeModules.nixvim
  ];

  home.username = "mbyte";
  home.homeDirectory = "/home/mbyte";
  home.stateVersion = "25.11";
}
