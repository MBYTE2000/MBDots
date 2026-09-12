{ config, pkgs, lib, ... }:
# Niri user-config, декларативно из этого модуля.
#
# config.kdl собирается склейкой отдельных секций из `./config/*.kdl` —
# так проще ревьюить (input отдельно от binds отдельно от layout).
# Файл включает `./noctalia.kdl` — он тоже деплоится home-manager’ом.
let
  # Порядок склейки задан явно, а не через readDir, — чтобы сохранить логику
  # секций (input → outputs → layout → window-rules → binds → include).
  parts = [
    "00-header"          # комментарии + prefer-no-csd
    "10-input"           # keyboard/touchpad/mouse/tablet
    "20-outputs"         # HDMI-A-1, DP-1
    "30-layout"          # gaps, borders, focus-ring, structure
    "40-hotkey-overlay"  # help panel
    "50-animations"      # springs
    "60-window-rules"    # per-app rules
    "70-overview"        # workspace overview background/etc
    "75-layer-rules"     # layer-shell rules (waybar, notifications)
    "80-binds"           # keybindings — самая большая секция
    "99-tail"            # include noctalia.kdl + trailing
  ];

  readPart = name: builtins.readFile (./config + "/${name}.kdl");
  concatenated = lib.concatStringsSep "\n" (map readPart parts);
in
{
  # Основной конфиг: собираем из секций.
  xdg.configFile."niri/config.kdl".text = concatenated;

  # Вспомогательный include — цветовая тема от noctalia, которую main config
  # подтягивает через `include "./noctalia.kdl"`.
  xdg.configFile."niri/noctalia.kdl".source = ./noctalia.kdl;
}
