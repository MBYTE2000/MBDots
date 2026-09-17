{ pkgs, lib, ... }:
# Ghostty — GPU-ускоренный Wayland-native терминал (замена alacritty).
# stylix.targets.ghostty пишет [colors] + font в ~/.config/ghostty/config,
# здесь только поведенческие настройки.
{
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      # Общий вид
      window-padding-x = 12;
      window-padding-y = 12;
      background-opacity = lib.mkForce 0.85;  # stylix ставит 1.0
      # ГЛАВНОЕ: в ghostty 1.3+ дефолт `background-opacity-cells = false`.
      # Это значит прозрачным становится только пустой фон, а любая ячейка
      # с текстом/prompt рисуется solid — визуально окно с открытой оболочкой
      # выглядит "непрозрачным", особенно когда в фокусе (курсор двигается,
      # ячейки перерисовываются). Включаем — теперь весь буфер прозрачный.
      background-opacity-cells = true;
      background-blur = false;                # blur на Wayland → solid
      alpha-blending = "linear-corrected";    # корректный alpha-mixing
      confirm-close-surface = false;
      window-decoration = false;              # без CSD — niri сам рисует рамку

      # Шрифт задаёт stylix; размер по умолчанию берётся из stylix.fonts.sizes.terminal.

      # Управление
      copy-on-select = true;
      mouse-hide-while-typing = true;
      cursor-style = "block";
      cursor-style-blink = false;
      shell-integration-features = "no-cursor";

      # Скрыть панель заголовка, если Ghostty решит рисовать через GTK
      gtk-titlebar = false;
      gtk-single-instance = true;
    };
  };
}
