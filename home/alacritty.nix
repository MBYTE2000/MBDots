{ pkgs, lib, ... }:
# Alacritty под управлением home-manager — иначе `stylix.targets.alacritty`
# формально включён, но не может писать в файл (юзер редактировал его вручную).
# Теперь ~/.config/alacritty/alacritty.toml — symlink на home-manager store,
# stylix инъектит [colors] + семейство шрифтов из stylix.fonts.monospace.
{
  programs.alacritty = {
    enable = true;
    settings = {
      env.TERM = "xterm-256color";

      window = {
        startup_mode = "Windowed";
        title = "Alacritty";
        dynamic_title = true;
        padding = { x = 12; y = 12; };
        # stylix ставит opacity = 1.0 — форсируем нашу прозрачность.
        opacity = lib.mkForce 0.8;
      };

      # font / colors инъектит stylix. Поведенческие настройки — здесь.

      # Раньше был бинд Shift+Enter → ESC+CR: home-manager TOML-formatter
      # отказывается писать raw control-байты в строку, а иначе alacritty
      # не интерпретирует . Если понадобится — добавляй руками в
      # home.file.".config/alacritty/keybinds.toml" и импортируй его через
      # settings.import.
    };
  };
}
