{ config, pkgs, inputs, system, ... }:


{ 
  imports = [ 
    inputs.nix-flatpak.homeManagerModules.nix-flatpak 
    inputs.nixcord.homeModules.nixcord
    inputs.librewolf-nix.hmModules.${system}.default
    inputs.nixvim.homeModules.nixvim
    ./noctalia.nix
    ./discord.nix
  ];
 
  home.username = "mbyte";
  home.homeDirectory = "/home/mbyte"; 
  home.stateVersion = "25.11";
  home.packages = with pkgs; [
    #neovim
    btop
    fuzzel
    kdePackages.dolphin
    materialgram
    vlc
    fastfetch
    wallust
    onlyoffice-desktopeditors
    gimp
    kdePackages.kdenlive
    yt-dlp
    zoxide
    steam
    kdePackages.okular
    qbittorrent
    texlive.combined.scheme-full
    claude-code
    #rpi-imager
  ];
  #home.pointerCursor = {
  #  gtk.enable = true;
  #  package = pkgs.bibata-cursors;
  #  name = "Bibata-Modern-Classic";
  #  size = 24;
  #};
  

  librewolf-nix = {
    enable = true;
  };

  #home.file.".cache/noctalia/wallpapers.json" = {
  #  text = builtins.toJSON {
  #    defaultWallpaper = "~/Wallpapers/WP.mp4";
  #    wallpapers = {
  #      #"DP-1" = "/path/to/monitor/wallpaper.png";
  #    };
  #  };
  #};

  #xdg.desktopEntries = {
  #  vesktop-wayland = {
  #    name = "Vesktop (Wayland)";
  #    exec = "vesktop --ozone-platform=wayland --disable-features=WebRtcAllowInputVolumeAdjustment";
  #    type = "Application";
  #    terminal = false;
  #    categories = [ "Network" ];
  #    };
  #};
  services.flatpak = { 
    packages = [
      "org.vinegarhq.Sober"
    ];
  };
  programs.nixvim = {
    enable = true;
    #colorschemes.catppuccin.enable = true;
    plugins.lualine.enable = true;
  };

  programs.yazi = 
  {
    enable = true;
  };
  programs.mangohud = {
    enable = true;
  };
}
