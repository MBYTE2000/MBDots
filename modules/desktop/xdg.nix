{ pkgs, ... }:
{
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
    config = {
      common.default = [ "gnome" "gtk" ];
    };
  };

  # Обход краша ScreenCast (xdg-desktop-portal-gnome + Nvidia Vulkan).
  # Forced GL renderer вместо Vulkan/ngl — иначе Electron-приложения падают.
  systemd.user.services.xdg-desktop-portal-gnome.environment.GSK_RENDERER = "gl";
}
