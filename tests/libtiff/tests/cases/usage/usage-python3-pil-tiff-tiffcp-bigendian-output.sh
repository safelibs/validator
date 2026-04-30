#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiffcp-bigendian-output
# @title: Pillow TIFF tiffcp big-endian output
# @description: Writes a little-endian TIFF with Pillow, runs tiffcp -B to convert it to big-endian byte order, and verifies the MM*.. magic and that Pillow can still decode the resulting file with matching dimensions and mode.
# @timeout: 180
# @tags: usage, image, python, cli, endian
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/le.tiff"
be="$tmpdir/be.tiff"

python3 - <<'PY' "$src"
import sys
from PIL import Image

size = (16, 12)
pixels = [
    ((x * 13) % 256, (y * 17) % 256, ((x + y) * 11) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(sys.argv[1])
PY

validator_require_file "$src"

# Sanity check: Pillow writes little-endian magic.
python3 - <<'PY' "$src"
import sys
with open(sys.argv[1], "rb") as fh:
    head = fh.read(4)
assert head == b"II*\x00", head
PY

tiffcp -B "$src" "$be"
validator_require_file "$be"

# tiffcp -B forces big-endian output: magic must be MM*..
python3 - <<'PY' "$be"
import sys
with open(sys.argv[1], "rb") as fh:
    head = fh.read(4)
assert head == b"MM\x00\x2a", head
PY

python3 - <<'PY' "$src" "$be"
import sys
from PIL import Image

src, be = sys.argv[1], sys.argv[2]
with Image.open(src) as a, Image.open(be) as b:
    a.load(); b.load()
    assert a.size == b.size == (16, 12), (a.size, b.size)
    assert a.mode == b.mode == "RGB", (a.mode, b.mode)
    # Pillow decodes both byte orders to identical pixel data.
    assert a.tobytes() == b.tobytes(), "endian round-trip pixels differ"
    print("bigendian", a.size, a.mode)
PY
