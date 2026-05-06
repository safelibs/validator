#!/usr/bin/env bash
# @testcase: usage-python3-pil-r11-tiff-tiffset-orientation-tag
# @title: tiffset rewrites the Orientation tag and tiffinfo reports the new sense
# @description: Saves an RGB TIFF, runs tiffset -s 274 6 to set Orientation=6 (row 0 rhs, col 0 top), and verifies tiffinfo's "Orientation" line reports the new orientation token rather than the default.
# @timeout: 60
# @tags: usage, tiff, tiffset, orientation
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/orient.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (32, 24), (200, 50, 90)).save(sys.argv[1], 'TIFF')
PY

tiffset -s 274 6 "$path"
tiffinfo "$path" | grep -E 'Orientation: row 0 rhs, col 0 top' >/dev/null
