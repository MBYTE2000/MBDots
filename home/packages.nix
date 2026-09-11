{ pkgs, ... }:
{
  home.packages = with pkgs; [
    btop
    #fuzzel                      # больше не используется — лаунчер через noctalia
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
    protonup-qt
    esptool
    rns
    heroic
    chromium
    python3Packages.huggingface-hub
    opencode
    nvitop
  ];
}
