{ config, pkgs, lib, ... }:
# Niri user-config, полностью декларативный внутри Nix.
#
# Каждая секция KDL лежит в отдельном .nix-файле в ./sections/ и возвращает
# KDL-строку. Здесь мы просто их конкатенируем и деплоим один config.kdl.
#
# Плюсы vs raw .kdl:
#   • всё редактируется как Nix (можно вставлять ${config.stylix.*}, if-then-else и т.д.);
#   • grep/find/eval работают с одним расширением;
#   • дерево видно в flake sources.
let
  # Порядок склейки задан явно — важно для binds vs layout vs input.
  parts = [
    ./sections/00-header.nix          # comments + prefer-no-csd
    ./sections/10-input.nix           # keyboard / touchpad / mouse / tablet
    ./sections/20-outputs.nix         # HDMI-A-1, DP-1
    ./sections/30-layout.nix          # gaps / borders / focus-ring / structure
    ./sections/40-hotkey-overlay.nix  # help panel
    ./sections/50-animations.nix      # springs
    ./sections/60-window-rules.nix    # per-app правила
    ./sections/70-overview.nix        # overview фон/etc
    ./sections/75-layer-rules.nix     # layer-shell правила
    ./sections/80-binds.nix           # keybindings — самая большая секция
    ./sections/99-tail.nix            # include noctalia.kdl + trailing
  ];

  # Второй layout-блок — цвета фокусной рамки, границ, теней, tab-indicator’а
  # и insert-hint’а генерируются из активной stylix-палитры. Раньше это был
  # статичный `noctalia.kdl` с хард-кодом; теперь любой смены темы (stylix.image
  # или base16Scheme) хватает, чтобы niri пере-раскрасился на следующем `update`.
  colors = config.lib.stylix.colors;
  stylixNiriKdl = ''
    layout {
        focus-ring {
            active-color   "#${colors.base0D}"
            inactive-color "#${colors.base02}"
            urgent-color   "#${colors.base08}"
        }

        border {
            active-color   "#${colors.base0D}"
            inactive-color "#${colors.base02}"
            urgent-color   "#${colors.base08}"
        }

        shadow {
            color "#${colors.base00}70"
        }

        tab-indicator {
            active-color   "#${colors.base0D}"
            inactive-color "#${colors.base03}"
            urgent-color   "#${colors.base08}"
        }

        insert-hint {
            color "#${colors.base0D}80"
        }
    }
  '';
in
{
  # Главный конфиг: собираем из Nix-строк.
  xdg.configFile."niri/config.kdl".text =
    lib.concatMapStringsSep "\n" (p: import p) parts;

  # Include-цель для config.kdl. Раньше — статичный файл, экспортированный
  # noctalia-shell; теперь генерируется из stylix-палитры, чтобы цвета niri
  # шли из той же base16-схемы, что и остальной desktop.
  xdg.configFile."niri/noctalia.kdl".text = stylixNiriKdl;
}
