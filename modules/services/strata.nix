{ config, lib, pkgs, ... }:
let
  # Using the official Strata repository (pinned to v0.2.6 tag)
  strata-src = pkgs.fetchurl {
    url = "https://github.com/Niko1221/Strata/archive/refs/tags/v0.2.6.tar.gz";
    sha256 = "sha256-xlDX6DNXuOkWQ6Ea+4fDcZ7onVtKQVlMFll4OhjAnMI=";
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
  
  # Build Strata as a Python application
  strata-package = strata-python.pkgs.buildPythonApplication {
    pname = "strata";
    version = "0.1.51";
    src = strata-src;
    
    nativeBuildInputs = [ 
      strata-python.pkgs.setuptools 
      strata-python.pkgs.wheel 
    ];
    
    # All runtime dependencies from requirements.txt
    propagatedBuildInputs = [
      strata-python.pkgs.numpy
      strata-python.pkgs.jinja2
      strata-python.pkgs.regex
      strata-python.pkgs.pyyaml
      strata-python.pkgs.tqdm
      strata-python.pkgs.requests
      strata-python.pkgs.pillow
      strata-python.pkgs.psutil
      strata-python.pkgs.markupsafe
      strata-python.pkgs.certifi
      strata-python.pkgs.truststore
      strata-python.pkgs."charset-normalizer"
      strata-python.pkgs.idna
      strata-python.pkgs.urllib3
      strata-python.pkgs.textual
      strata-python.pkgs.colorama
    ];
    
    format = "other";
    dontBuild = true;
    
    # Install Strata CLI modules
    installPhase = ''
      mkdir -p $out/bin $out/lib
      cp -r strata_cli $out/lib/
      cp -r strata_control $out/lib/
      cp -r serve $out/lib/
      cp -r tools $out/lib/
      cp -r strata.py $out/lib/
      
      # Find all site-packages in the Nix store for Python 3.12
      SITE_PACKAGES=$(find /nix/store -name "site-packages" -type d -path "*/lib/python3.12/*" 2>/dev/null | grep -v "dist-info" | tr '\n' ':')
      
      # Create wrapper script that uses the venv
      cat > $out/bin/strata << 'WRAPPER'
#!/usr/bin/env python3
# -*- python -*-
#
# The strata CLI launcher
#
import os, sys

# Add all Nix store site-packages to PYTHONPATH
SITE_PACKAGES = "$(find /nix/store -name "site-packages" -type d -path "*/lib/python3.12/*" 2>/dev/null | grep -v "dist-info" | tr '\n' ':')"
os.environ['PYTHONPATH'] = SITE_PACKAGES

# Add Strata lib directory
lib_dir = "$out/lib"
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
      pkgs.uv  # Required by Strata setup.sh on NixOS
    ];
  };
}
