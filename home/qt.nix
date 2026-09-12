{ pkgs, ... }:
# Интеграция Qt/KDE-приложений (Dolphin, Okular, Gwenview, Kdenlive) в non-KDE
# сессию (Niri/Wayland). Раньше Dolphin отображался "криво": не подхватывал
# stylix-палитру, миссинг иконки, странные размеры — потому что platformTheme
# не был задан и часть kdePackages-хелперов не стояли.
#
# stylix.targets.qt/kde уже пишут qt5ct/qt6ct + kdeglobals. Здесь мы
# подключаем platform-theme "qtct" через home-manager qt module (он экспортит
# QT_QPA_PLATFORMTHEME=qt6ct в окружение), плюс докидываем нужные KDE Frameworks.
{
  qt = {
    enable = true;
    platformTheme.name = "qtct";       # qt5ct + qt6ct — оба видят stylix-палитру
    style.name = "kvantum";            # рендерер виджетов; stylix пишет Base16Kvantum
  };

  home.packages = with pkgs; [
    # Стиль-движок Kvantum. Именно он читает Base16Kvantum, который пишет
    # stylix. Без этих пакетов Qt-приложения ставят QT_STYLE_OVERRIDE=kvantum,
    # не находят libkvantum.so и падают на fusion → белые кнопки в Dolphin.
    kdePackages.qtstyleplugin-kvantum         # Qt6 (Dolphin/Okular/Gwenview 25.x)
    libsForQt5.qtstyleplugin-kvantum          # Qt5 (kdenlive, старые KDE-приложения)

    # Qt config UIs (stylix пишет в них; сам qt6ct-плагин нужен как platformTheme)
    qt6Packages.qt6ct
    libsForQt5.qt5ct

    # Frameworks / интеграция
    kdePackages.plasma-integration     # Wayland/portal мосты для KDE-приложений
    kdePackages.breeze-icons           # fallback-иконки (некоторые dialogs требуют)
    kdePackages.kio-fuse               # KIO ↔ FUSE (dolphin → sftp/smb/…)

    # Dolphin-компаньоны
    kdePackages.dolphin-plugins        # git / bazaar / mercurial аннотации

    # Приложения, на которые ссылается xdg-mime
    kdePackages.gwenview               # image viewer (default для image/*)
    kdePackages.ark                    # archive manager (application/zip и т.д.)
  ];
}
