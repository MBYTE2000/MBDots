{ ... }:
# Starship prompt для zsh. Минимальная кастомизация — stylix.targets.starship
# автоматически подкрашивает символы под base16-палитру.
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;         # компактный prompt
      command_timeout = 800;

      # Показывать статус последней команды слева от prompt-символа.
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol   = "[❯](bold red)";
      };

      # Директория — только последние 2 сегмента.
      directory = {
        truncation_length = 2;
        truncate_to_repo  = true;
      };

      # Git-статус компактный.
      git_status = {
        format = "([$all_status$ahead_behind]($style) )";
      };
    };
  };
}
