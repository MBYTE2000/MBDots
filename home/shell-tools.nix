{ ... }:
# Мелкие shell-утилиты: lsd (ls-replacement), zoxide (cd-replacement).
# Каждый — с интеграцией zsh (алиасы, hooks).
{
  # lsd — цветной ls с иконками. Алиасы ls/l/la/lla/lt уже в system zsh.nix,
  # чтобы работать даже в root-shell. Здесь только модуль и его конфиг.
  programs.lsd = {
    enable = true;
    settings = {
      classic = false;
      color.when = "auto";
      icons = {
        when = "auto";
        theme = "fancy";
        separator = " ";
      };
      layout = "grid";
      sorting = {
        column = "name";
        dir-grouping = "first";
      };
      permission = "rwx";
      total-size = false;
    };
  };

  # zoxide — умный `cd`. Учит частопосещаемые директории → команда `z <часть-пути>`.
  # `enableZshIntegration = true` регистрирует hook chpwd и алиас `z`.
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd cd" ];   # z → cd; оригинальный cd остаётся как `\cd`
  };
}
