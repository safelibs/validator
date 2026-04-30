#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiffcp-bigtiff-bigendian
# @title: Pillow TIFF tiffcp -8 -B BigTIFF big-endian
# @description: Writes a classic little-endian TIFF with Pillow, repackages it as a BigTIFF (-8) in big-endian byte order (-B) via tiffcp, and verifies the MM..\x2b magic (BigTIFF big-endian) plus that tiffinfo reports the correct geometry. Pillow 10.2.0 on Ubuntu 24.04 cannot decode BigTIFF reliably, so the readback is performed with tiffinfo + libtiff itself rather than Pillow.
# @timeout: 180
# @tags: usage, image, python, cli, format, endian
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/classic.tiff"
big="$tmpdir/bigbe.tiff"

python3 - <<'PY' "$src"
import sys
from PIL import Image

size = (24, 16)
pixels = [
    ((x * 9) % 256, (y * 13) % 256, ((x + y) * 7) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(sys.argv[1])
PY

validator_require_file "$src"

# Sanity: Pillow output is classic little-endian (II*\x00).
python3 - <<'PY' "$src"
import sys
with open(sys.argv[1], "rb") as fh:
    head = fh.read(4)
assert head == b"II*\x00", head
PY

# tiffcp -8 -B: BigTIFF, big-endian byte order.
tiffcp -8 -B "$src" "$big"
validator_require_file "$big"

# BigTIFF big-endian magic: MM\x00\x2b. Classic big-endian is MM\x00\x2a.
python3 - <<'PY' "$big"
import sys
with open(sys.argv[1], "rb") as fh:
    head = fh.read(4)
assert head == b"MM\x00\x2b", head
PY

# Round-trip via libtiff itself (tiffinfo can read BigTIFF; Pillow 10.2.0
# cannot reliably decode BigTIFF, so we do not ask it to here).
report="$tmpdir/info.txt"
tiffinfo "$big" >"$report"
validator_assert_contains "$report" "Image Width: 24 Image Length: 16"
validator_assert_contains "$report" "Photometric Interpretation: RGB color"
validator_assert_contains "$report" "Samples/Pixel: 3"

# Re-roundtrip: tiffcp BigTIFF-BE back to classic LE so Pillow can verify pixels.
classic_again="$tmpdir/again.tiff"
tiffcp -L "$big" "$classic_again"
validator_require_file "$classic_again"

python3 - <<'PY' "$src" "$classic_again"
import sys
from PIL import Image

src, again = sys.argv[1], sys.argv[2]
with Image.open(src) as a, Image.open(again) as b:
    a.load(); b.load()
    assert a.size == b.size == (24, 16), (a.size, b.size)
    assert a.mode == b.mode == "RGB", (a.mode, b.mode)
    assert a.tobytes() == b.tobytes(), "bigtiff round-trip pixels differ"
    print("bigtiff-be", a.size, a.mode)
PY
