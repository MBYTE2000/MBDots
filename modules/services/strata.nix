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
      mkdir -p $out/bin $out/lib $out/scripts
      cp -r strata_cli $out/lib/
      cp -r strata_control $out/lib/
      cp -r serve $out/lib/
      cp -r tools $out/lib/
      cp -r strata.py $out/lib/
      
      # Copy setup scripts
      cp setup.sh $out/scripts/
      cp setup.py $out/scripts/
      cp strata.py $out/scripts/
      cp requirements.txt $out/scripts/
      cp requirements-monitor.txt $out/scripts/
      cp update.sh $out/scripts/
      cp bench.sh $out/scripts/
      cp chat.py $out/scripts/
      
      # Find all site-packages in the Nix store for Python 3.12
      SITE_PACKAGES=$(find /nix/store -name "site-packages" -type d -path "*/lib/python3.12/*" 2>/dev/null | grep -v "dist-info" | tr '\n' ':')
      
      # Create wrapper script that uses the venv
      cat > $out/bin/strata << 'WRAPPER'
#!/usr/bin/env python3
# -*- python -*-
#
# The strata CLI launcher
#
import os, sys, subprocess

# Find all Nix store site-packages and add to PYTHONPATH
try:
    result = subprocess.run(
        ['find', '/nix/store', '-name', 'site-packages', '-type', 'd', '-path', '*/lib/python3.12/*'],
        capture_output=True, text=True, timeout=10
    )
    site_packages = result.stdout.strip().split('\n')
    os.environ['PYTHONPATH'] = ':'.join(site_packages)
except:
    pass

# Add Strata lib directory
lib_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)), "..", "lib")
sys.path.insert(0, lib_dir)
from strata_cli.cli import main
main()
WRAPPER
      chmod +x $out/bin/strata
      
      # Create strata-setup wrapper script
      cat > $out/bin/strata-setup << 'SETUP_WRAPPER'
#!/usr/bin/env bash
# strata-setup - Run Strata setup.sh from the Nix package
# Usage: strata-setup [options]
set -e

# Find the strata package directory via the strata binary symlink
STRATA_BIN="/run/current-system/sw/bin/strata"

if [ ! -L "$STRATA_BIN" ]; then
    echo "Error: strata binary not found at $STRATA_BIN" >&2
    exit 1
fi

# Resolve the symlink to get the actual Nix store path
STRATA_PKG_DIR="$(readlink -f "$STRATA_BIN")"
STRATA_PKG_DIR="$(dirname "$STRATA_PKG_DIR")"  # Remove /bin
STRATA_PKG_DIR="$(dirname "$STRATA_PKG_DIR")"  # Remove /bin again to get package root

# Verify the scripts directory exists
if [ ! -d "$STRATA_PKG_DIR/scripts" ]; then
    echo "Error: scripts directory not found in $STRATA_PKG_DIR" >&2
    exit 1
fi

# Copy scripts to a temporary directory (Nix store is read-only)
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

# Copy and fix permissions
cp -r "$STRATA_PKG_DIR/scripts" "$TMP_DIR/"
chmod -R u+w "$TMP_DIR/scripts"

cd "$TMP_DIR/scripts"

# Set PYTHONPATH to include Nix store lib directory
export PYTHONPATH="$STRATA_PKG_DIR/lib:$PYTHONPATH"

# Run setup.sh with all arguments
exec bash setup.sh "$@"
SETUP_WRAPPER
      chmod +x $out/bin/strata-setup
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
