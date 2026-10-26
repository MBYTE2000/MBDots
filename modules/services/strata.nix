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
      "textual"
      "colorama"
    ];
    
    format = "other";
    dontBuild = true;
    
    # Run setup.sh to create venv with all dependencies
    installPhase = ''
      # Create virtual environment using uv
      uv venv --managed-python --seed --python 3.12 .venv
      
      # Activate venv and run setup.py in "venv-only" mode (no downloads)
      # We only need the Python environment, not the engine/model downloads
      source .venv/bin/activate
      
      # Install dependencies from requirements.txt
      uv pip install -r requirements.txt
      
      # Copy Strata modules to output
      mkdir -p $out/bin $out/lib
      cp -r strata_cli $out/lib/
      cp -r strata_control $out/lib/
      cp -r serve $out/lib/
      cp -r tools $out/lib/
      cp -r strata.py $out/lib/
      
      # Copy venv to output
      cp -r .venv $out/venv
      
      # Create wrapper script that uses the venv
      cat > $out/bin/strata << 'WRAPPER'
#!/usr/bin/env bash
# The strata CLI launcher using venv
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
VENV="$SCRIPT_DIR/../venv"
export PYTHONPATH="$LIB_DIR:$PYTHONPATH"
exec "$VENV/bin/python" -c "
import sys
sys.path.insert(0, '$LIB_DIR')
from strata_cli.cli import main
main()
" "$@"
WRAPPER
      chmod +x $out/bin/strata
      
      # Create a convenience script to run setup.py directly
      cat > $out/bin/strata-setup << 'SETUPWRAPPER'
#!/usr/bin/env bash
# Run setup.py from the venv
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV="$SCRIPT_DIR/../venv"
exec "$VENV/bin/python" "$SCRIPT_DIR/../lib/setup.py" "$@"
SETUPWRAPPER
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
