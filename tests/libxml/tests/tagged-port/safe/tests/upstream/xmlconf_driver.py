#!/usr/bin/env python3

from pathlib import Path
import runpy
import sys


ROOT = Path(__file__).resolve().parents[3]
LOG = Path.cwd() / "check-xml-test-suite.log"
SCRIPT = ROOT / "original" / "check-xml-test-suite.py"

if LOG.exists():
    LOG.unlink()

sys.argv = [str(SCRIPT), *sys.argv[1:]]
runpy.run_path(str(SCRIPT), run_name="__main__")
