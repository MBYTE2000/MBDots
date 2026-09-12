# Секция 99-tail — сгенерирована из config.kdl, теперь редактируется как Nix.
# Возвращает KDL-строку, которая склеивается в home/niri/default.nix.
''
    // Powers off the monitors. To turn them back on, do any input like
    // moving the mouse or pressing any other key.
    Mod+Shift+P { power-off-monitors; }
}


include "./noctalia.kdl"
''
