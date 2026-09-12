# Секция 75-layer-rules — сгенерирована из config.kdl, теперь редактируется как Nix.
# Возвращает KDL-строку, которая склеивается в home/niri/default.nix.
''
layer-rule {
    match namespace="^noctalia-wallpaper-*"
    opacity 0.0
}
//layer-rule {
//    match namespace="^noctalia-wallpaper-DP-3$"
//    opacity 0.0
//}

layer-rule {
    match namespace="^mpvpaper$"
    place-within-backdrop true
}
''
