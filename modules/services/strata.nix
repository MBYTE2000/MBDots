{ config, lib, pkgs, ... }:
let
  # Using the official Strata repository (pinned to v0.2.6 tag commit)
  strata-flake = pkgs.fetchFromGitHub {
    owner = "Niko1221";
    repo = "Strata";
    rev = "4b9e05a2a806a3fe24f7b2560d98626c37dade35";
    sha256 = "sha256-d4AFr2b+EW+keFN9vaKse8lkGR0r0m+7OqBr+CPHwvw=";
  };
  
  # Build Strata as a Python application
  strata-package = (pkgs.python312.pkgs).buildPythonApplication {
    pname = "strata";
    version = "0.1.51";
    src = strata-flake;
    
    nativeBuildInputs = [ 
      (pkgs.python312.pkgs).setuptools 
      (pkgs.python312.pkgs).wheel 
    ];
    
    requirements = [
      "numpy"
      "jinja2"
      "regex"
      "pyyaml"
      "tqdm"
      "requests"
      "pillow"
      "psutil"
      "markupsafe"
      "certifi"
      "truststore"
      "charset-normalizer"
      "idna"
      "urllib3"
    ];
    
    format = "other";
    dontBuild = true;
    
    installPhase = ''
      mkdir -p $out/bin $out/lib
      
      # Copy Python modules
      cp -r strata_cli $out/lib/
      cp -r strata_control $out/lib/
      cp -r serve $out/lib/
      cp -r strata.py $out/lib/
      
      # Create Python wrapper
      cat > $out/bin/strata << 'WRAPPER'
#!/usr/bin/env python3
# -*- python -*-
#
# The strata CLI launcher.
#
import os, sys
script_dir = os.path.dirname(os.path.realpath(__file__))
lib_dir = os.path.normpath(os.path.join(script_dir, "..", "lib"))
sys.path.insert(0, lib_dir)
from strata_cli.cli import main
main()
WRAPPER
      chmod +x $out/bin/strata
    '';
  };
in
{
  config = lib.mkIf config.myConfig.services.strata.enable {
    # Strata CLI in PATH
    environment.systemPackages = [
      strata-package
    ];
  };
}
