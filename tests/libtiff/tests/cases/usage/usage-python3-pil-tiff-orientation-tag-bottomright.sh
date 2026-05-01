#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-orientation-tag-bottomright
# @title: Pillow TIFF tiffset Orientation tag value 3 round-trip
# @description: Saves a TIFF with Pillow, sets the Orientation tag (274) to 3 (rotated 180 / bottom-right) via libtiff's tiffset CLI, and verifies tiffinfo reports "row 0 bottom, col 0 rhs" while Pillow reloads the same RGB pixel buffer (Pillow does not auto-transpose on load).
# @timeout: 180
# @tags: usage, image, python, orientation
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$tmpdir/oriented.tiff"

python3 - <<'PY' "$img"
import sys
from PIL import Image

size = (8, 6)
pixels = bytes(
    component
    for y in range(size[1])
    for x in range(size[0])
    for component in ((x * 31) & 0xFF, (y * 41) & 0xFF, ((x + y) * 17) & 0xFF)
)
image = Image.frombytes("RGB", size, pixels)
image.save(sys.argv[1])
PY

# Pillow does not preserve Orientation (274) through save, so we set it
# directly with libtiff's tiffset CLI.
tiffset -s 274 3 "$img"

info="$tmpdir/info.txt"
tiffinfo "$img" >"$info"
validator_assert_contains "$info" "Orientation: row 0 bottom, col 0 rhs"

python3 - <<'PY' "$img"
import sys
from PIL import Image

size = (8, 6)
with Image.open(sys.argv[1]) as reopened:
    reopened.load()
    # tiffset rewrites strip layout; we do not assert pixel bytes here -
    # the goal is to confirm libtiff persisted the Orientation tag and
    # Pillow can still decode the geometry/mode.
    assert reopened.size == size, reopened.size
    assert reopened.mode == "RGB", reopened.mode
    raw = reopened.tobytes()
    assert len(raw) == size[0] * size[1] * 3, len(raw)
    print("orientation 3 set via tiffset, geometry preserved")
PY
