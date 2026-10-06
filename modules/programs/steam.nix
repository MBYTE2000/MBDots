{ config, pkgs, lib, ... }:
# programs.steam.enable = true — правильный способ поставить Steam в NixOS.
# Даёт FHS-окружение (steam-run), 32-bit graphics libs, udev-правила для
# контроллеров, gamescope-интеграцию, разрешения для friends/voice.
# Просто `pkgs.steam` в home.packages НЕ работает: бинарь есть, но окружения нет.
lib.mkIf config.myConfig.categories.gaming.enable {
  programs.steam = {
    enable = true;

    # Steam Remote Play — стрим игр на другие устройства в LAN.
    remotePlay.openFirewall = true;

    # Dedicated servers (открывает порты только если хочется хостить сервер).
    # dedicatedServer.openFirewall = false;

    # Steam Input controllers — Xbox / DualShock / прочие геймпады.
    extraCompatPackages = with pkgs; [
      proton-ge-bin        # современный Proton-GE для non-verified игр
    ];
  };

  # gamemoded — понижает latency и приоритизирует игру когда она в фокусе.
  programs.gamemode.enable = true;

  # gamescope — компоновщик от Valve для гейминга (SteamDeck-style HUD, FSR upscale).
  # Запуск: `gamescope -f -- steam` или через Steam launch options.
  programs.gamescope.enable = true;
}
