{ osConfig, pkgs, lib, ... }:
# Пакеты пользователя. Core-пакеты ставятся всегда. Остальное разложено по
# категориям — см. myConfig.categories в hosts/<host>/default.nix.
# osConfig — nixos-level config, home-manager прокидывает автоматом.
let
  c = osConfig.myConfig.categories;
in
{
  home.packages = with pkgs; [
    # ----- Core (always on): mini-tools без которых не жить -----
    btop
    fuzzel
    kdePackages.dolphin
    fastfetch
    yt-dlp
    wallust
    claude-code
    esptool
    rns
    python3Packages.huggingface-hub
    opencode
  ]
  # ----- Multimedia -----
  ++ lib.optionals c.multimedia.enable [
    gimp
    kdePackages.kdenlive
    vlc
    chromium
    heroic             # heroic тоже кидаю сюда — Epic/GOG launcher
  ]
  # ----- Office -----
  ++ lib.optionals c.office.enable [
    onlyoffice-desktopeditors
    kdePackages.okular
  ]
  # ----- Communications -----
  ++ lib.optionals c.comms.enable [
    materialgram
    # vesktop/vencord ставит nixcord через home/discord.nix (gate'ится там же)
  ]
  # ----- Fileshare -----
  ++ lib.optionals c.fileshare.enable [
    qbittorrent
  ]
  # ----- Gaming (сопутствующие утилиты, Steam/Proton — в modules/programs/steam.nix) -----
  ++ lib.optionals c.gaming.enable [
    protonup-qt        # UI для Proton-GE
  ]
  # ----- Dev -----
  ++ lib.optionals c.dev.enable [
    texlive.combined.scheme-full
  ]
  # ----- AI/ML (CLI tooling; ollama-cuda ставит modules/services/ollama.nix) -----
  ++ lib.optionals c.ai.enable [
    nvitop             # GPU-мониторинг
    # python3Packages.huggingface-hub оставлен в core — он всегда полезен
    # (не только для AI).
  ];
}
