{ config, lib, ... }:
{
  config = lib.mkIf config.myConfig.programs.zsh.enable {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;

      shellAliases = {
        ls  = "lsd";
        l   = "lsd -l";
        la  = "lsd -a";
        lla = "lsd -la";
        lt  = "lsd --tree";
        y   = "yazi";
        edit = "sudo -e";

        # === Пересборка системы ===
        # `switch` — атомарно: если сборка/активация упадёт, текущая система не меняется.
        # После успеха создаётся новое поколение → пункт в GRUB → откат в 1 клик.
        # GRUB держит configurationLimit=30 последних (см. modules/core/boot.nix).
        update = "sudo nixos-rebuild switch --flake /etc/nixos#nixos";

        # Активировать без записи в загрузчик (проверить, откатится сам после ребута).
        update-test = "sudo nixos-rebuild test --flake /etc/nixos#nixos";

        # Собрать в ./result и не активировать (максимально безопасно).
        update-build = "sudo nixos-rebuild build --flake /etc/nixos#nixos";

        # Обновить flake inputs (nixpkgs, home-manager, nixcord, …) и пересобрать.
        update-full = "sudo nix flake update /etc/nixos && sudo nixos-rebuild switch --flake /etc/nixos#nixos";

        # === Откат ===
        # Мгновенный откат на предыдущее поколение (без ребута).
        rollback = "sudo nixos-rebuild switch --rollback";
        # Список всех поколений с датами.
        generations = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
        # Показать чем текущее отличается от предыдущего.
        gen-diff = "nvd diff /run/current-system /nix/var/nix/profiles/system-*-link 2>/dev/null | tail -50";

        restart-noctalia = "pkill -f noctalia-shell && sleep 1 && nohup noctalia-shell > /dev/null 2>&1 &";
      };

      histSize = 10000;
      histFile = "$HOME/.zsh_history";
      setOptions = [ "HIST_IGNORE_ALL_DUPS" ];

      ohMyZsh = {
        enable = true;
        plugins = [ "git" "z" "history" "sudo" ];
        theme = "agnoster";
      };
    };
    programs.starship.enable = true;
  };
}
