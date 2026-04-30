#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiffdump-key-tags
# @title: Pillow TIFF tiffdump key tag inspection
# @description: Writes an RGB TIFF with Pillow, runs tiffdump on it, and asserts the low-level dump reports the expected key directory tags (ImageWidth, ImageLength, BitsPerSample, Photometric, SamplesPerPixel) with the values we wrote.
# @timeout: 180
# @tags: usage, image, python, cli, metadata
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/dump.tiff"
dump="$tmpdir/dump.txt"

python3 - <<'PY' "$src"
import sys
from PIL import Image

size = (24, 16)
pixels = [
    ((x * 5) % 256, (y * 7) % 256, ((x + y) * 3) % 256)
    for y in range(size[1])
    for x in range(size[0])
]
image = Image.new("RGB", size)
image.putdata(pixels)
image.save(sys.argv[1])
PY

validator_require_file "$src"
tiffdump "$src" >"$dump"
validator_require_file "$dump"

# Magic header: little-endian classic TIFF written by Pillow.
validator_assert_contains "$dump" "Magic: 0x4949"
validator_assert_contains "$dump" "ClassicTIFF"

# Key directory tags with the canonical names tiffdump prints.
validator_assert_contains "$dump" "ImageWidth (256)"
validator_assert_contains "$dump" "ImageLength (257)"
validator_assert_contains "$dump" "BitsPerSample (258)"
validator_assert_contains "$dump" "Photometric (262)"
validator_assert_contains "$dump" "SamplesPerPixel (277)"
validator_assert_contains "$dump" "StripOffsets (273)"

# Width=24 and Length=16 were written above, RGB has SamplesPerPixel=3
# and 8 bits per sample x3 bands.
grep -E "ImageWidth \(256\) (LONG|SHORT) \([34]\) 1<24>" "$dump" >/dev/null
grep -E "ImageLength \(257\) (LONG|SHORT) \([34]\) 1<16>" "$dump" >/dev/null
grep -E "BitsPerSample \(258\) SHORT \(3\) 3<8 8 8>" "$dump" >/dev/null
grep -E "SamplesPerPixel \(277\) SHORT \(3\) 1<3>" "$dump" >/dev/null
grep -E "Photometric \(262\) SHORT \(3\) 1<2>" "$dump" >/dev/null

printf 'tiffdump %s\n' "$(wc -l <"$dump") lines"
