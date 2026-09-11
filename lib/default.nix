{ lib }:
rec {
  # Собрать список путей ко всем .nix файлам директории, кроме default.nix
  importDir = dir:
    let
      entries = builtins.readDir dir;
      names = builtins.attrNames entries;
      files = builtins.filter (n:
        entries.${n} == "regular"
        && n != "default.nix"
        && lib.hasSuffix ".nix" n
      ) names;
      dirs = builtins.filter (n: entries.${n} == "directory") names;
    in
      map (n: dir + "/${n}") files
      ++ map (n: dir + "/${n}") dirs;

  # Короткий mkEnableOption для однотипных фич
  mkFeature = desc: lib.mkEnableOption desc;
}
