{ config, lib, pkgs, ... }:
let
  # Using the official Strata repository (pinned to v0.2.6 tag)
  strata-src = pkgs.fetchurl {
    url = "https://github.com/Niko1221/Strata/archive/refs/tags/v0.2.6.tar.gz";
    sha256 = "sha256-xlDX6DNXuOkWQ6Ea+4fDcZ7onVtKQVlMFll4OhjAnMI=";
  };
  
  # Build Strata as a Python application
  strata-package = (pkgs.python312.pkgs).buildPythonApplication {
    pname = "strata";
    version = "0.1.51";
    src = strata-src;
    
    nativeBuildInputs = [ 
      (pkgs.python312.pkgs).setuptools 
      (pkgs.python312.pkgs).wheel 
      pkgs.uv
    ];
    
    # All runtime dependencies from requirements.txt
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
    
    # Optional TUI dependencies from requirements-monitor.txt
    optionalDependencies = [
      "textual"
      "colorama"
    ];
    
    format = "other";
    dontBuild = true;
    
    installPhase = ''
      mkdir -p $out/bin $out/lib
      cp -r strata_cli $out/lib/
      cp -r strata_control $out/lib/
      cp -r serve $out/lib/
      cp -r tools $out/lib/
      cp -r strata.py $out/lib/
      
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
  
  # Python environment with all Strata dependencies
  strata-python = pkgs.python312.withPackages (ps: [
    ps.numpy
    ps.jinja2
    ps.regex
    ps.pyyaml
    ps.tqdm
    ps.requests
    ps.pillow
    ps.psutil
    ps.markupsafe
    ps.certifi
    ps.truststore
    ps."charset-normalizer"
    ps.idna
    ps.urllib3
    ps.textual
    ps.colorama
  ]);
in
{
  config = lib.mkIf config.myConfig.services.strata.enable {
    # Strata CLI in PATH
    environment.systemPackages = [
      strata-package
      pkgs.uv  # Required by Strata setup.sh on NixOS
    ];
    
    # Shell hook to add Strata Python packages to PATH
    environment.shellInit = ''
      # Add Strata Python environment to PATH if it exists
      if [ -d "/nix/store" ]; then
        STRATA_PYTHON=$(find /nix/store -name "strata-python*" -type d 2>/dev/null | head -1)
        if [ -n "$STRATA_PYTHON" ]; then
          export PATH="$STRATA_PYTHON/bin:$PATH"
        fi
      fi
    '';
  };
}
