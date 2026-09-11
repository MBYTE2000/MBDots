{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    alacritty
    xwayland-satellite
    mpvpaper
    awww  # раньше был swww, переименовано в nixpkgs
    pavucontrol
    gnome-calendar
    hyprlock
    mako
    vulkan-loader
    vulkan-tools
    lsd
    rustc
    cargo
    rustup
    gcc
    unzip
    zip
    unrar
    nodejs
    sddm-astronaut
    rpi-imager
    libmtp
    gvfs
    kdePackages.kio-extras
    gamescope
    jq
    lutris
    winetricks
    gnumake
    cmake
    cudaPackages.cudatoolkit
    cudaPackages.cuda_cudart
    # nvd — diff между поколениями системы (для `gen-diff` alias)
    nvd
  ];
}
