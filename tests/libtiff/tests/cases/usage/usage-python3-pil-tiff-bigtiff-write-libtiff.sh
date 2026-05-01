#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-bigtiff-write-libtiff
# @title: Pillow TIFF tiffcp -8 BigTIFF little-endian magic + multipage preserved
# @description: Writes a two-page classic little-endian TIFF with Pillow, repackages it as a BigTIFF (-8) via tiffcp without changing byte order, and verifies the II\x00\x2b magic (BigTIFF little-endian), that tiffinfo enumerates two directories with the expected geometries, and that tiffcp -L round-trips the BigTIFF back to a classic TIFF whose pixel buffers match the Pillow originals.
# @timeout: 180
# @tags: usage, image, python, bigtiff
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/classic.tiff"
big="$tmpdir/big.tiff"

python3 - <<'PY' "$src"
import sys
from PIL import Image

page0 = Image.new("RGB", (24, 16))
page0.putdata([
    ((x * 7) % 256, (y * 11) % 256, ((x + y) * 5) % 256)
    for y in range(16)
    for x in range(24)
])
page1 = Image.new("RGB", (12, 8))
page1.putdata([
    ((x * 17) % 256, (y * 19) % 256, ((x ^ y) * 13) % 256)
    for y in range(8)
    for x in range(12)
])
page0.save(sys.argv[1], save_all=True, append_images=[page1])

with open(sys.argv[1], "rb") as fh:
    head = fh.read(4)
assert head == b"II*\x00", head
PY

# tiffcp -8 (LE BigTIFF). No -B, so byte order stays little-endian.
tiffcp -8 "$src" "$big"
validator_require_file "$big"

python3 - <<'PY' "$big"
import sys
with open(sys.argv[1], "rb") as fh:
    head = fh.read(8)
assert head[:4] == b"II\x2b\x00", head
PY

info="$tmpdir/info.txt"
tiffinfo "$big" >"$info"
validator_assert_contains "$info" "TIFF Directory at offset"
# Geometry of both pages preserved.
validator_assert_contains "$info" "Image Width: 24 Image Length: 16"
validator_assert_contains "$info" "Image Width: 12 Image Length: 8"

# Round-trip BigTIFF back to classic LE so Pillow can verify pixels.
again="$tmpdir/again.tiff"
tiffcp "$big" "$again"

python3 - <<'PY' "$src" "$again"
import sys
from PIL import Image, ImageSequence

with Image.open(sys.argv[1]) as a, Image.open(sys.argv[2]) as b:
    a_frames = [f.copy() for f in ImageSequence.Iterator(a)]
    b_frames = [f.copy() for f in ImageSequence.Iterator(b)]
    assert len(a_frames) == len(b_frames) == 2, (len(a_frames), len(b_frames))
    for fa, fb in zip(a_frames, b_frames):
        assert fa.size == fb.size, (fa.size, fb.size)
        assert fa.mode == fb.mode == "RGB", (fa.mode, fb.mode)
        assert fa.tobytes() == fb.tobytes(), "bigtiff multipage pixel mismatch"
    print("bigtiff-le", [f.size for f in a_frames])
PY
