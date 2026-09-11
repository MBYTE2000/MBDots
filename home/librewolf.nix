{ config, pkgs, lib, ... }:
# Используем модуль Firefox с подменой пакета на LibreWolf.
# Enterprise Policies — единственный надёжный способ ставить расширения декларативно.
{
  # Указываем Stylix какие профили Firefox тематизировать (иначе warning).
  stylix.targets.firefox.profileNames = [ "default" ];

  programs.firefox = {
    enable = true;
    package = pkgs.librewolf;

    policies = {
      ExtensionSettings = {
        "vimium-c@gdh1995.cn" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-c/latest.xpi";
          installation_mode = "force_installed";
        };
        "{fbcef8e5-0d39-4d3a-a6b5-ca1837ee0c8a}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/tampermonkey/latest.xpi";
          installation_mode = "force_installed";
        };
        "{5cb624c2-3f71-4942-a0b6-b628f2aae1c4}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/sideberry/latest.xpi";
          installation_mode = "force_installed";
        };
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
        "jid1-93WyvawrT2dP4Q@jetpack" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/traduzir-paginas-web/latest.xpi";
          installation_mode = "force_installed";
        };
        "privacybadger@eff.org" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger/latest.xpi";
          installation_mode = "force_installed";
        };
        "{762f9885-5a13-4abd-9c77-433dcd38b8fd}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/return-youtube-dislikes/latest.xpi";
          installation_mode = "force_installed";
        };
        "sponsorBlocker@ajay.app" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };

    profiles.default = {
      settings = {
        "extensions.update.enabled" = true;
        "extensions.strictCompatibility" = false;
        "privacy.trackingprotection.enabled" = true;
        "webgl.disabled" = true;
        "extensions.autoDisableScopes" = 0;
      };
      bookmarks = [
        { name = "NixOS"; url = "https://nixos.org/"; }
        "separator"
        { name = "Поисковики";
          bookmarks = [
            { name = "Поиск по Nixpkgs"; url = "https://search.nixos.org/packages?query=%s"; }
            { name = "Home Manager";     url = "https://nix-community.github.io/home-manager/"; }
          ];
        }
      ];
      search = {
        default = "google";
        engines = {
          "nix-packages" = {
            urls = [{ template = "https://search.nixos.org/packages?query={searchTerms}"; }];
            definedAliases = [ "@np" ];
          };
          "nixos-wiki" = {
            urls = [{ template = "https://wiki.nixos.org/w/index.php?search={searchTerms}"; }];
            definedAliases = [ "@nw" ];
          };
          "bing".metaData.hidden = true;
        };
      };
    };
  };
}
