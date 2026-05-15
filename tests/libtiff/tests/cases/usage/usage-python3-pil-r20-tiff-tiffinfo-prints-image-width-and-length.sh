#!/usr/bin/env bash
# @testcase: usage-python3-pil-r20-tiff-tiffinfo-prints-image-width-and-length
# @title: tiffinfo CLI on a Pillow-written TIFF prints Image Width and Image Length lines
# @description: Saves a 9x7 RGB TIFF via Pillow, runs the tiffinfo CLI on it, and asserts the output contains a line matching "Image Width: 9" and a line matching "Image Length: 7", confirming the libtiff inspection tool reads back the dimensions Pillow wrote.
# @timeout: 60
# @tags: usage, tiff, python, tiffinfo, dimensions, r20
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/wl.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (9, 7), (10, 20, 30)).save(sys.argv[1], 'TIFF')
PY

tiffinfo "$path" >"$tmpdir/info" 2>&1

grep -E 'Image Width: *9' "$tmpdir/info" >/dev/null || { cat "$tmpdir/info" >&2; exit 1; }
grep -E 'Image Length: *7' "$tmpdir/info" >/dev/null || { cat "$tmpdir/info" >&2; exit 1; }
echo "ok tiffinfo W=9 L=7"
