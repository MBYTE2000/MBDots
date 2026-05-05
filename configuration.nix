# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./stylix.nix
    ];

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Use the systemd-boot EFI boot loader.
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "ntfs" ];
  boot.loader = {
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = true;
      minegrub-theme = {
        enable = true;
        splash = "100% Flakes!";
        background = "background_options/1.8  - [Classic Minecraft].png";
        boot-options-count = 4;
      };
    };
    efi.canTouchEfiVariables = true;
  };
  boot.plymouth = {
    enable = true;
    #theme = "bgrt";
  };
  boot.initrd.systemd.enable = true;
  boot.kernelParams = [ "quiet" "splash" "nvidia_drm.modeset=1" ];
  networking.hostName = "MB-PC"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  networking.networkmanager.ensureProfiles.profiles = {
    "ethPort" = {
      connection = {
        id = "ethPort";
        type = "ethernet";
        interface-name = "enp6s0";
      };
      ipv4 = {
        address1 = "10.20.0.10/16,10.20.0.1";
        dns = "10.20.0.1";
        method = "manual";
      };
     };
  };
  # Set your time zone.
  time.timeZone = "Europe/Minsk";
  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };
  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_drm" "nvidia_uvm" ];
  boot.initrd.systemd.services.plymouth-start = {
    after = [ "systemd-modules-load.service" ];
    requires = [ "systemd-modules-load.service" ];
  };
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vulkan-loader
      vulkan-validation-layers
      vulkan-extension-layer 
    ];
  }; 

  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.xserver.videoDrivers = ["nvidia"];
  #services.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    open = false; # Use the open-source kernel module
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true; # Перенаправляет открытие ссылок через портал

    # Необходимые порталы
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome  # Важно: именно gnome, а не только gtk
    ];

    # Явно указываем приоритет. Для Niri и Electron-приложений часто требуется gnome
    config = {
      common.default = [ "gnome" ];
    };
  };

  services.displayManager = {
    #gdm.enable = true;
    sddm.enable = true;
    sddm.wayland.enable = true;
    defaultSession = "niri";
    sddm.theme = "sddm-astronaut-theme";
    sddm.extraPackages = [ pkgs.sddm-astronaut ];
  };




  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  services.flatpak = {
    enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.mbyte = {
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
  };
  
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ls = "lsd";
      l = "lsd -l";
      la = "lsd -a";
      lla = "lsd -la";
      lt = "lsd --tree";
      y = "yazi";
      edit = "sudo -e";
      update = "sudo nixos-rebuild switch --flake /etc/nixos#MB-PC";
      restart-noctalia = "pkill -f noctalia-shell && sleep 1 && nohup noctalia-shell > /dev/null 2>&1 &";
    };

    histSize = 10000;
    histFile = "$HOME/.zsh_history";
    setOptions = [
      "HIST_IGNORE_ALL_DUPS"
    ];

    ohMyZsh = {
      enable = true;
      plugins = [ "git" "z" "history" "sudo" ];
      theme = "agnoster";
    };

  };


  programs.starship = 
  {
    enable = true;
    #enableZshIntegration = true;
  };

  programs.niri = {
    enable = true;
    # xwayland.enable = true;
  };
  #programs.waybar = {
  #  enable = true;
  #};

#  stylix = {
#    enable = true;
#    autoEnable = false;
#    image = ./WP.png;   # положите файл рядом
#    #base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
#    polarity = "dark";
#  };

 
  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    git
    vim 
    wget
    alacritty
    fuzzel
    xwayland-satellite
    mpvpaper
    swww
    pavucontrol
    gnome-calendar
    #wlogout
    hyprlock
    mako
    vulkan-loader
    vulkan-tools
    lsd
    #thefuck
    rustc
    cargo
    rustup
    gcc
    unzip
    unrar
    nodejs
    nvidia-vaapi-driver
    sddm-astronaut
    rpi-imager
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    OZONE_PLATFORM = "wayland";
    ELCTRON_OZONE_PLATFORM_HINT = "auto";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  fonts.packages = with pkgs; [ 
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
    corefonts
    liberation_ttf
    dejavu_fonts
    noto-fonts-cjk-sans
    cm_unicode
    libertine
    times-newer-roman
  ];
  fonts.enableDefaultPackages = true;

  fonts.fontconfig = {
    antialias = true;
    hinting.enable = true;
  };
  
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?

}

