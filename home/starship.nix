{ ... }:
# Starship — округлые pill-сегменты вместо угловатых powerline-стрелок.
# stylix.targets.starship раскрашивает base16-палитрой; переходы `/`
# (nf-pl-left_half_circle_thick / right_half_circle_thick) дают "капсульный"
# вид без острых углов.
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      add_newline = true;
      command_timeout = 800;

      # Каждая pill-группа обрамлена  слева и  справа (round caps),
      # цвет капсулы = bg-color сегмента. Соседние капсулы разделены пробелом.
      format = builtins.concatStringsSep "" [
        # user@host в base09 (акцентная капсула)
        "[](fg:base09)"
        "$os$username[@](bg:base09 fg:base00)$hostname"
        "[](fg:base09)"
        " "

        # cwd в base02 (тёмный контейнер)
        "[](fg:base02)"
        "$directory"
        "[](fg:base02)"
        " "

        # git в base0D (accent-blue капсула, только если repo)
        "$git_branch$git_status"

        # правый край — cmd_duration + часы, без bg, лёгким серым
        "$fill"
        "$cmd_duration$time"
        "$line_break"

        # символ приглашения — просто цветной, без капсулы
        "$character"
      ];

      fill = { symbol = " "; };

      # --- OS/user/host капсула ---------------------------------------------
      os = {
        disabled = false;
        style = "bg:base09 fg:base00";
        symbols = {
          NixOS = " ";
          Linux = " ";
          Macos = " ";
          Windows = " ";
        };
        format = "[ $symbol ]($style)";
      };

      username = {
        show_always = true;
        style_user = "bg:base09 fg:base00 bold";
        style_root = "bg:base08 fg:base00 bold";
        format = "[$user]($style)";
      };

      hostname = {
        ssh_only = false;
        style = "bg:base09 fg:base00";
        format = "[$hostname]($style)";
      };

      # --- Directory капсула ------------------------------------------------
      directory = {
        style = "bg:base02 fg:base05";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncate_to_repo = true;
        truncation_symbol = "…/";
        read_only = " ";
        read_only_style = "bg:base02 fg:base08";
        substitutions = {
          "Documents"    = "󰈙";
          "Downloads"    = " ";
          "Music"        = " ";
          "Pictures"     = " ";
          "nixos-config" = " nixos";
        };
      };

      # --- Git капсула (base0D) — сама рисует свои  capsuli ---------------
      git_branch = {
        symbol = "";
        style = "fg:base0D";
        format = "[](fg:base0D)[ $symbol $branch ](bg:base0D fg:base00)";
      };

      git_status = {
        style = "fg:base0D";
        format = "[$all_status$ahead_behind](bg:base0D fg:base00)[](fg:base0D) ";
        conflicted = "= ";
        ahead      = "⇡\${count} ";
        behind     = "⇣\${count} ";
        diverged   = "⇕ ";
        untracked  = "? ";
        stashed    = "≡ ";
        modified   = "!";
        staged     = "+";
        renamed    = "»";
        deleted    = "✘";
      };

      # --- Правый край: время выполнения + часы -----------------------------
      cmd_duration = {
        min_time = 500;
        style = "fg:base04 italic";
        format = "[ took $duration ]($style)";
      };

      time = {
        disabled = false;
        time_format = "%R";
        style = "fg:base03";
        format = "[ 󰥔 $time ]($style)";
      };

      # --- Prompt символ ----------------------------------------------------
      character = {
        success_symbol = "[❯](bold fg:base0B)";
        error_symbol   = "[❯](bold fg:base08)";
        vimcmd_symbol  = "[❮](bold fg:base0D)";
      };

      line_break = { disabled = false; };

      # --- Языки отключены (уменьшаем визуальный шум; при желании включить —
      #     раскомментируй нужный модуль и добавь его в format между dir и fill)
      c        = { disabled = true; };
      rust     = { disabled = true; };
      golang   = { disabled = true; };
      nodejs   = { disabled = true; };
      python   = { disabled = true; };
      java     = { disabled = true; };
      nix_shell = {
        # Оставляем только nix-shell — он бывает часто и полезен визуально.
        disabled = false;
        symbol = " ";
        style = "fg:base0C italic";
        format = "[$symbol$state( \\($name\\))]($style) ";
      };
    };
  };
}
