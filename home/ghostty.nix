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
      # Отключаем размытие фона — на Wayland/Niri оно превращается в solid
      # (compositor не умеет корректно смешивать). Без него прозрачность
      # работает и в focused, и в unfocused состоянии.
      background-blur = false;
      # linear-corrected — правильное смешивание alpha на Wayland компоsitor'ах
      # (native выдаёт solid-looking результат из-за некорректного blending'а).
      alpha-blending = "linear-corrected";
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
