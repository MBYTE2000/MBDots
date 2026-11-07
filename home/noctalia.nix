{ inputs, pkgs, ... }:
# Noctalia v5 (нативный C++ shell, конфиг в ~/.config/noctalia/config.toml).
#
# Перенесено с v4: в v4 реально работал ~/.config/noctalia/settings.json
# (декларативный конфиг до него не доходил), поэтому настройки ниже
# повторяют именно его: тот же набор виджетов на баре, док, часы и т.д.
#
# Цвета, шрифт и прозрачность дока/уведомлений/OSD задаёт stylix
# (stylix.targets.noctalia → кастомная палитра "stylix"), чтобы shell
# совпадал по цветам с niri и остальной системой.
#
# Модуль из flake сам отключает встроенный programs.noctalia из home-manager.
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia = {
    enable = true;
    # Самая свежая версия — прямо из flake noctalia, а не из nixpkgs.
    package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
    # Автозапуск — через spawn-at-startup в niri (см. home/niri/sections/30-layout.nix).

    settings = {
      shell = {
        avatar_path = "~/.face";
        telemetry_enabled = false;
        animation = {
          enabled = true;
          speed = 1.0;
        };
        # v4: shadowDirection = "bottom_right"
        shadow.direction = "down_right";
      };

      # Обои рисует mpvpaper; в v4 слой обоев noctalia был спрятан
      # layer-rule'ом с opacity 0, здесь просто отключаем его.
      wallpaper.enabled = false;

      notification.layer = "overlay";

      # v4: lockOnSuspend = true
      lockscreen.lock_before_suspend = true;

      dock = {
        enabled = true;
        position = "bottom";
        auto_hide = true;
        # Как в v4: скрытый док не резервирует место снизу.
        reserve_space = false;
      };

      # v4: barType "simple" во всю ширину, прижат к верху,
      # outerCorners → вогнутые углы, frameRadius 12, showCapsule.
      bar.main = {
        position = "top";
        background_opacity = 0.93;
        margin_ends = 0;
        margin_edge = 0;
        concave_edge_corners = true;
        radius = 12;
        widget_spacing = 6;
        capsule = true;

        start = [ "launcher" "clock" "cpu" "temp" "ram" "active_window" "media" ];
        center = [ "workspaces" ];
        end = [ "tray" "notifications" "battery" "volume" "brightness" "control-center" ];
      };

      widget = {
        launcher.glyph = "rocket";

        # v4: "HH:mm ddd, MMM dd"
        clock = {
          format = "{:%H:%M %a, %b %d}";
          tooltip_format = "{:%H:%M %a, %b %d}";
        };

        # v4 SystemMonitor (compact): CPU usage + CPU temp + RAM.
        cpu = { type = "sysmon"; stat = "cpu_usage"; };
        temp = { type = "sysmon"; stat = "cpu_temp"; };
        ram = { type = "sysmon"; stat = "ram_used"; };

        active_window.max_length = 145;

        # v4 MediaMini: скрыт, когда ничего не играет.
        media = {
          artist_first = true;
          hide_when_no_media = true;
        };

        # v4 Workspace: labelMode index, подписи только у занятых.
        workspaces = {
          show_labels = true;
          label_source = "id";
          labels_only_when_occupied = true;
          hide_when_empty = false;
          focused_color = "primary";
          occupied_color = "secondary";
          empty_color = "secondary";
        };

        tray = {
          drawer = true;
          hide_passive = false;
        };

        # v4 NotificationHistory: виден всегда, с бейджем непрочитанных.
        notifications.hide_when_no_unread = false;

        # v4 Battery: graphic.
        battery.display_mode = "graphic";

        # v4 Volume/Brightness: displayMode "onhover" → peek.
        volume = {
          peek = true;
          actions.middle = "exec pavucontrol";
        };
        brightness.peek = true;
      };
    };
  };
}
