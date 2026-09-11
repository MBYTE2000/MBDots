{ pkgs, lib, ... }:
# Discord через nixcord + Vesktop.
#
# Почему Vesktop, а не официальный Discord + Vencord:
#   Vesktop имеет встроенный захват аудио через PipeWire (виртуальный микрофон
#   `vencord-screen-share`), что критично для screen share со звуком на Wayland.
#   Chromium от официального Discord этого не умеет — на NVIDIA/Wayland
#   демонстрация экрана либо чёрная, либо без звука.
#
# Что нужно на уровне системы (уже включено в modules/):
#   - hardware.graphics.enable = true        (иначе WebRTC capture молча падает)
#   - services.pipewire.enable = true
#   - xdg.portal.extraPortals содержит xdg-desktop-portal-gnome
#     (у portal-gtk нет ScreenCast — недостаточно)
#   - systemd.user.services.xdg-desktop-portal-gnome.environment.GSK_RENDERER = "gl"
#     (обход краша GNOME portal на Nvidia proprietary)
{
  programs.nixcord = {
    enable = true;

    # Только Vesktop, официальный Discord не ставим.
    discord.enable = false;
    vesktop = {
      enable = true;
      # Использовать Vencord из nixpkgs (быстрее подтягивает патчи + меньше пересборок)
      useSystemVencord = true;
    };

    # Настройки Vencord (шарятся между Discord/Vesktop; применяются в Vesktop
    # через встроенный Vencord).
    config = {
      # Косметика окна
      frameless = true;
      disableMinSize = true;

      themeLinks = [
        "https://catppuccin.github.io/discord/dist/catppuccin-mocha.theme.css"
      ];

      plugins = {
        # --- Screen share fixes (ГЛАВНОЕ, из-за чего этот рефактор) ---
        # Снимает лимит 2500 kbps и чинит утечку CPU при демонстрации.
        webScreenShareFixes.enable = true;
        # UI для выбора разрешения/FPS и звуков системы:
        # плагин webScreenShare добавлен в upstream 4evy/nixcord, но пока
        # отсутствует в форке FlameFlag/nixcord. Если после смены input
        # он появится — раскомментируй:
        # webScreenShare.enable = true;

        # --- QoL, безопасное ---
        # Убирает предупреждение "Hold Up!" в DevTools
        noDevtoolsWarning.enable = true;
        # Открывает скрытые эксперименты Discord (для тестов новых фич)
        experiments.enable = true;

        # messageLogger убран: логгирование удалённых сообщений — тяжёлый плагин
        # и потенциальный ToS-риск. Если нужен — верни строчкой:
        #   messageLogger.enable = true;
      };
    };
  };
}
