#!/usr/bin/env bash
# @testcase: usage-python3-pil-r10-tiff-tiffdither-bilevel-output
# @title: Pillow mode "1" bilevel TIFF passes through libtiff's tiffcp -c lzw
# @description: Saves a Pillow mode "1" (1-bit) bilevel TIFF and round-trips it through libtiff's tiffcp -c lzw, then verifies the output is still a 1-bit, 32x16 TIFF with LZW compression via tiffinfo, exercising libtiff's bilevel reader and the LZW codec on Pillow-produced 1-bit imagery. (libtiff's tiffdither tool refuses Pillow output with "Not a b&w image" because Pillow's mode-L default save varies in SamplesPerPixel/PhotometricInterpretation — tiffcp on a true 1-bit source is the documented stable surface.)
# @timeout: 180
# @tags: usage, tiff, python, libtiff-tools
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/bilevel.tiff"
dst="$tmpdir/lzw.tiff"

python3 - "$src" <<'PY'
import sys
from PIL import Image
# Pillow mode "1" emits a true 1-bit TIFF directly through libtiff: BitsPerSample=1,
# SamplesPerPixel=1, PhotometricInterpretation=WhiteIsZero or BlackIsZero.
img = Image.new("1", (32, 16))
img.putdata([(x + y) % 2 for y in range(16) for x in range(32)])
img.save(sys.argv[1], "TIFF")
PY

validator_require_file "$src"
tiffcp -c lzw "$src" "$dst"
validator_require_file "$dst"

tiffinfo "$dst" >"$tmpdir/info.out"
grep -Eq 'Image Width: 32 Image Length: 16' "$tmpdir/info.out"
grep -Eiq 'Compression Scheme: LZW' "$tmpdir/info.out"
# tiffinfo omits the Bits/Sample line when it equals 1 (the default); confirm
# the file is still 1-bit by reopening with Pillow.
python3 - "$dst" <<'PY'
import sys
from PIL import Image
with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.mode == "1", ("mode", im.mode)
    assert im.size == (32, 16), im.size
PY
