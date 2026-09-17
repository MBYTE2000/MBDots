{ pkgs, config, lib, ... }:
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

  # -- ВАЖНО: обход quirk home-manager / useUserPackages ----------------------
  # useUserPackages=true не заносит share/{color-schemes,Kvantum,plasma,…}
  # из home-manager-path в /etc/profiles/per-user/mbyte/share/. Из-за этого
  # KDE-приложения не находили ColorScheme=Stylix (kdeglobals указывает на
  # него, но Stylix.colors был доступен только внутри home-path). Итог —
  # dolphin рисовал белые кнопки, потому что палитра не подтягивалась.
  #
  # 1) Отдаём Stylix.colors и Kvantum-темы в user's XDG_DATA_HOME напрямую —
  #    приложения всегда читают ~/.local/share первым.
  home.file.".local/share/color-schemes/Stylix.colors".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.local/state/home-manager/gcroots/current-home/home-path/share/color-schemes/Stylix.colors";

  # 2) Добавляем home-manager-path/share в XDG_DATA_DIRS. sessionVariables
  #    пишется в ~/.profile и подхватывается SDDM/PAM на следующем логине
  #    → niri и всё что оно спавнит увидит правильный DATA_DIRS.
  home.sessionVariables = {
    XDG_DATA_DIRS = lib.concatStringsSep ":" [
      "${config.home.homeDirectory}/.local/state/home-manager/gcroots/current-home/home-path/share"
      "\${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    ];
  };
}
