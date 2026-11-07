# Секция 60-window-rules — сгенерирована из config.kdl, теперь редактируется как Nix.
# Возвращает KDL-строку, которая склеивается в home/niri/default.nix.
''
window-rule {
    // This regular expression is intentionally made as specific as possible,
    // since this is the default config, and we want no false positives.
    // You can get away with just app-id="wezterm" if you want.
    match app-id=r#"^org\.wezfurlong\.wezterm$"#
    default-column-width {}
}

// Open the Firefox picture-in-picture player as floating by default.
window-rule {
    // This app-id regular expression will work for both:
    // - host Firefox (app-id is "firefox")
    // - Flatpak Firefox (app-id is "org.mozilla.firefox")
    match app-id=r#"librewolf"# title="^Picture-in-Picture$"
    open-floating true
}



// Example: block out two password managers from screen capture.
// (This example rule is commented out with a "/-" in front.)
/-window-rule {
    match app-id=r#"^org\.keepassxc\.KeePassXC$"#
    match app-id=r#"^org\.gnome\.World\.Secrets$"#

    block-out-from "screen-capture"

    // Use this instead if you want them visible on third-party screenshot tools.
    // block-out-from "screencast"
}

// Example: enable rounded corners for all windows.
// (This example rule is commented out with a "/-" in front.)
window-rule {
    geometry-corner-radius 12
    clip-to-geometry true
}

window-rule {
    match app-id="equibop"
    draw-border-with-background false
}

// Global: focus-ring / border рисуются ВОКРУГ окон, а не solid прямоугольником
// ПОД ними. Без этого focus-ring просвечивает как solid цвет через любое
// semi-transparent окно (ghostty c background-opacity=0.85 → выглядит непрозрачным
// когда в фокусе). См. https://yalter.github.io/niri/Configuration:-Window-Rules
window-rule {
    draw-border-with-background false
}

// Терминал открывается чуть шире стандартной половины экрана.
window-rule {
    match app-id=r#"^com\.mitchellh\.ghostty$"#
    default-column-width { proportion 0.6; }
}

// Окно настроек Noctalia v5 — плавающее (рекомендация noctalia для niri).
window-rule {
    match app-id="dev.noctalia.Noctalia"
    open-floating true
    default-column-width { fixed 1080; }
    default-window-height { fixed 920; }
}

// Нужно Noctalia v5 для действий в уведомлениях и активации окон.
debug {
    honor-xdg-activation-with-invalid-serial
}
''
