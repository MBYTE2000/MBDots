{ config, pkgs, lib, ... }:
# fastfetch с PNG-логотипом вместо ASCII. Ghostty поддерживает kitty
# image protocol, поэтому картинка рисуется настоящими пикселями.
let
  # Логотип — снимок Nix-снежинки из nixos-icons. Приятно вписывается
  # в терминальный вывод и всегда доступен как пакет.
  logo = "${pkgs.nixos-icons}/share/icons/hicolor/128x128/apps/nix-snowflake-white.png";
in
{
  programs.fastfetch = {
    enable = true;
    settings = {
      # PNG через kitty image protocol (Ghostty + kitty его понимают).
      # Если запустил fastfetch в терминале без поддержки — переключит на sixel/ascii сам.
      logo = {
        type = "kitty-direct";
        source = logo;
        width = 24;
        height = 12;
        padding = { top = 1; right = 3; };
      };

      display = {
        separator = "  ";
        color = {
          keys = "cyan";
          title = "magenta";
        };
      };

      modules = [
        # Заголовок: user@host
        { type = "title"; format = "{6}{1}{7}@{6}{2}"; }
        "separator"

        # Дистрибутив, ядро, десктоп
        { type = "os"; key = "󰍹"; }
        { type = "kernel"; key = "󰌢"; }
        { type = "wm"; key = "󱂬"; }
        { type = "shell"; key = ""; }
        { type = "terminal"; key = ""; }
        "break"

        # Железо
        { type = "cpu"; key = "󰻠"; format = "{1} ({3})"; }
        { type = "gpu"; key = "󰢮"; format = "{2}"; }
        { type = "memory"; key = "󰍛"; }
        { type = "disk"; key = "󰋊"; folders = "/"; }
        "break"

        # Прочее
        { type = "uptime"; key = "󰅐"; }
        { type = "packages"; key = "󰏖"; }
        "break"

        # Цветовые полосы — 2 строки по 8 цветов base16-палитры.
        {
          type = "colors";
          symbol = "circle";
          paddingLeft = 2;
        }
      ];
    };
  };
}
