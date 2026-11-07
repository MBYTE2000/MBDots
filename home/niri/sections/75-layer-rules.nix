# Секция 75-layer-rules — сгенерирована из config.kdl, теперь редактируется как Nix.
# Возвращает KDL-строку, которая склеивается в home/niri/default.nix.
# (Правило, прятавшее слой обоев noctalia v4, убрано: в v5 обои noctalia
#  отключены через wallpaper.enabled = false в home/noctalia.nix.)
''
layer-rule {
    match namespace="^mpvpaper$"
    place-within-backdrop true
}
''
