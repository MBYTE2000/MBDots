{ ... }:
# Файловые ассоциации через ~/.config/mimeapps.list (XDG стандарт).
# xdg-open, dolphin (Open With → Default), любой другой файл-мененджер
# читают этот файл. Раньше mimeapps.list был user-owned и содержал случайный
# набор (chromium как default browser), теперь — под home-manager.
let
  browser = "librewolf.desktop";                                # LibreWolf по умолчанию
  fm      = "org.kde.dolphin.desktop";
  pdf     = "org.kde.okular.desktop";
  images  = "org.kde.gwenview.desktop";
  archive = "org.kde.ark.desktop";
  video   = "vlc.desktop";
  audio   = "vlc.desktop";
  office  = "onlyoffice-desktopeditors.desktop";
in
{
  xdg.mimeApps = {
    enable = true;

    # `defaultApplications` — какое приложение открывать по двойному клику.
    defaultApplications = {
      # --- Web (главный запрос: браузер по умолчанию = LibreWolf) ---
      "text/html"                    = browser;
      "application/xhtml+xml"        = browser;
      "application/x-extension-html" = browser;
      "application/x-extension-htm"  = browser;
      "application/x-extension-shtml" = browser;
      "application/x-extension-xhtml" = browser;
      "application/x-extension-xht"  = browser;
      "x-scheme-handler/http"        = browser;
      "x-scheme-handler/https"       = browser;
      "x-scheme-handler/ftp"         = browser;
      "x-scheme-handler/chrome"      = browser;
      "x-scheme-handler/about"       = browser;
      "x-scheme-handler/unknown"     = browser;

      # --- Файловый менеджер ---
      "inode/directory"              = fm;

      # --- PDF / документы ---
      "application/pdf"              = pdf;
      "application/epub+zip"         = pdf;
      "application/x-cbz"            = pdf;
      "application/x-cbr"            = pdf;

      # --- Офис ---
      "application/msword"                                                       = office;
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document"  = office;
      "application/vnd.ms-excel"                                                 = office;
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"        = office;
      "application/vnd.ms-powerpoint"                                            = office;
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" = office;
      "application/vnd.oasis.opendocument.text"        = office;
      "application/vnd.oasis.opendocument.spreadsheet" = office;
      "application/vnd.oasis.opendocument.presentation" = office;
      "text/csv"                                       = office;

      # --- Картинки ---
      "image/png"                    = images;
      "image/jpeg"                   = images;
      "image/gif"                    = images;
      "image/webp"                   = images;
      "image/svg+xml"                = images;
      "image/bmp"                    = images;
      "image/tiff"                   = images;
      "image/heic"                   = images;
      "image/heif"                   = images;
      "image/x-icon"                 = images;
      "image/x-portable-pixmap"      = images;
      "image/x-portable-anymap"      = images;

      # --- Видео ---
      "video/mp4"                    = video;
      "video/x-matroska"             = video;
      "video/webm"                   = video;
      "video/quicktime"              = video;
      "video/x-msvideo"              = video;
      "video/mpeg"                   = video;
      "video/x-ms-wmv"               = video;
      "video/x-flv"                  = video;

      # --- Аудио ---
      "audio/mpeg"                   = audio;
      "audio/flac"                   = audio;
      "audio/x-vorbis+ogg"           = audio;
      "audio/ogg"                    = audio;
      "audio/opus"                   = audio;
      "audio/x-wav"                  = audio;
      "audio/aac"                    = audio;
      "audio/mp4"                    = audio;

      # --- Архивы ---
      "application/zip"              = archive;
      "application/x-tar"            = archive;
      "application/gzip"             = archive;
      "application/x-bzip2"          = archive;
      "application/x-xz"             = archive;
      "application/x-7z-compressed"  = archive;
      "application/x-rar"            = archive;
      "application/x-rar-compressed" = archive;
      "application/vnd.rar"          = archive;
    };
  };

  # Экспортим BROWSER=$(which librewolf) — некоторые CLI (git, xdg-open fallback,
  # некоторые tui-приложения) читают именно эту переменную, а не mimeapps.
  home.sessionVariables = {
    BROWSER = "librewolf";
    DEFAULT_BROWSER = "librewolf";
  };
}
