{ config, lib, ... }:
# System-level zsh — только чтобы shell был доступен из /etc/passwd
# и подхватывался completion от системных пакетов. Пользовательская
# конфигурация (aliases, ohmyzsh, plugins, integrations со starship/zoxide/lsd)
# живёт в home/zsh.nix — home-manager может писать нужные хуки в ~/.zshrc.
{
  config = lib.mkIf config.myConfig.programs.zsh.enable {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      # syntaxHighlighting/autosuggestions ставит home-manager (см. home/zsh.nix).
    };
  };
}
