{ ... }:
# Zsh под home-manager. Оно генерит ~/.zshrc и подтягивает integrations
# от других модулей: starship, zoxide, ghostty shell-hooks.
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      path = "$HOME/.zsh_history";
      ignoreAllDups = true;
    };

    shellAliases = {
      # lsd
      ls  = "lsd";
      l   = "lsd -l";
      la  = "lsd -a";
      lla = "lsd -la";
      lt  = "lsd --tree";

      # QoL
      y     = "yazi";
      edit  = "sudo -e";

      # === Пересборка системы ===
      update       = "sudo nixos-rebuild switch --flake /etc/nixos#nixos";
      update-test  = "sudo nixos-rebuild test  --flake /etc/nixos#nixos";
      update-build = "sudo nixos-rebuild build --flake /etc/nixos#nixos";
      update-full  = "sudo nix flake update /etc/nixos && sudo nixos-rebuild switch --flake /etc/nixos#nixos";

      # === Откат ===
      rollback    = "sudo nixos-rebuild switch --rollback";
      generations = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
      gen-diff    = "nvd diff /run/current-system /nix/var/nix/profiles/system-*-link 2>/dev/null | tail -50";

      restart-noctalia = "pkill -f noctalia-shell && sleep 1 && nohup noctalia-shell > /dev/null 2>&1 &";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "z" "history" "sudo" ];
      # theme убран — используем starship (см. home/starship.nix). Иначе они
      # оба будут рисовать prompt.
    };
  };
}
