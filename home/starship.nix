{ ... }:
# Starship prompt — двухстрочный, с nerd-icons и кучей language-модулей.
# stylix.targets.starship окрашивает символы под base16-палитру.
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      add_newline = true;
      command_timeout = 800;

      # Двухстрочный prompt:
      # <icon> user@host  <dir> <git>  <lang> <cmd_duration>
      # <sym>
      format = builtins.concatStringsSep "" [
        "[](fg:base09)"          # левое ушко
        "$os"
        "$username"
        "[@](bg:base09 fg:base00)"
        "$hostname"
        "[](fg:base09 bg:base02)"
        "$directory"
        "[](fg:base02 bg:base0D)"
        "$git_branch"
        "$git_status"
        "[](fg:base0D bg:base01)"
        "$c$rust$golang$nodejs$python$java$nix_shell"
        "[](fg:base01)"
        "$fill"
        "$cmd_duration"
        "$time"
        "$line_break"
        "$character"
      ];

      fill = { symbol = " "; };

      # --- Левая часть: пользователь, хост, cwd, git, языки ---
      os = {
        disabled = false;
        style = "bg:base09 fg:base00";
        symbols = {
          NixOS = " ";
          Linux = " ";
          Macos = " ";
          Windows = " ";
        };
      };

      username = {
        show_always = true;
        style_user = "bg:base09 fg:base00 bold";
        style_root = "bg:base09 fg:base08 bold";
        format = "[ $user]($style)";
      };

      hostname = {
        ssh_only = false;
        style = "bg:base09 fg:base00 bold";
        format = "[$hostname]($style)";
      };

      directory = {
        style = "bg:base02 fg:base05";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncate_to_repo = true;
        truncation_symbol = "…/";
        substitutions = {
          "Documents" = "󰈙";
          "Downloads" = " ";
          "Music"     = " ";
          "Pictures"  = " ";
          "nixos-config" = " nixos";
        };
      };

      git_branch = {
        symbol = " ";
        style = "bg:base0D fg:base00";
        format = "[ $symbol$branch ]($style)";
      };

      git_status = {
        style = "bg:base0D fg:base00";
        format = "[$all_status$ahead_behind ]($style)";
        conflicted = "= ";
        ahead     = "⇡\${count} ";
        behind    = "⇣\${count} ";
        diverged  = "⇕ ";
        untracked = "? ";
        stashed   = "≡ ";
        modified  = "! ";
        staged    = "+ ";
        renamed   = "» ";
        deleted   = "✘ ";
      };

      # --- Языки/окружения ---
      c        = { symbol = " ";   style = "bg:base01 fg:base05"; format = "[ $symbol($version) ]($style)"; };
      rust     = { symbol = " ";  style = "bg:base01 fg:base05"; format = "[ $symbol($version) ]($style)"; };
      golang   = { symbol = " ";   style = "bg:base01 fg:base05"; format = "[ $symbol($version) ]($style)"; };
      nodejs   = { symbol = " ";  style = "bg:base01 fg:base05"; format = "[ $symbol($version) ]($style)"; };
      python   = { symbol = " ";  style = "bg:base01 fg:base05"; format = "[ $symbol($version) ]($style)"; };
      java     = { symbol = " ";  style = "bg:base01 fg:base05"; format = "[ $symbol($version) ]($style)"; };
      nix_shell = { symbol = " ";  style = "bg:base01 fg:base05"; format = "[ $symbol$state( \\($name\\)) ]($style)"; };

      # --- Правая часть: время выполнения + часы ---
      cmd_duration = {
        min_time = 500;
        style = "fg:base03";
        format = "[ took $duration ]($style)";
      };

      time = {
        disabled = false;
        time_format = "%R";       # 24-часовой HH:MM
        style = "fg:base03";
        format = "[ $time ]($style)";
      };

      # --- Вторая строка: prompt-символ ---
      character = {
        success_symbol = "[❯](bold fg:base0B)";
        error_symbol   = "[❯](bold fg:base08)";
        vimcmd_symbol  = "[❮](bold fg:base0D)";
      };

      line_break = { disabled = false; };
    };
  };
}
