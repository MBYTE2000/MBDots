{ pkgs, inputs, system, ... }:
{
  imports = [
      inputs.noctalia.homeModules.default
  ];

  # configure options
  programs.noctalia-shell = {
    enable = true;
    settings = {
      # configure noctalia here
      bar = {
        barType = "simple";
        density = "default";
        position = "top";
        showCapsule = true;
	frameRadius = 12;
        outerCorners = true;
        widgets = {
          left = [
	    {
                id = "Launcher";
            }
            {
              formatHorizontal = "HH:mm";
              formatVertical = "HH mm";
              id = "Clock";
              useMonospacedFont = true;
              usePrimaryColor = true;
            }
	    {
                id = "ActiveWindow";
            }
          ];
          center = [
            {
              hideUnoccupied = false;
              id = "Workspace";
              labelMode = "none";
            }
          ];
          right = [
	    {
              id = "Tray";
            }
	    {
	      id = "ControlCenter";
	      useDistroLogo = false;
	      icon = "brand-among-us";  
	    }
          ];
        };
      };
      colorSchemes.predefinedScheme = "Monochrome";
      general = {
        avatarImage = "~/.face";
	scaleRatio = 1;
        radiusRatio = 1;
        iRadiusRatio = 1;
        boxRadiusRatio = 1;
        screenRadiusRatio = 1;
        animationSpeed = 1;
	enableShadows = true;
	shadowDirection = "bottom_right";
	shadowOffsetX = 2;
	shadowOffsetY = 3;
      };
      network = {
          wifiEnabled = false;
      };
      location = {
        monthBeforeDay = true;
        name = "Minsk, Belarus";
      };
      controlCenter = {
        iconMode = "tabler";
        icon = "brand-among-us";  
      };
      appLauncher = {
          enableClipboardHistory = true;
	  iconMode = "tabler";
      };
    };
  # this may also be a string or a path to a JSON file.
  };
}
