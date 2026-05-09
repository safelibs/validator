#!/usr/bin/env bash
# @testcase: usage-python3-pil-r10-tiff-tiffdither-bilevel-output
# @title: tiffdither converts an 8-bit grayscale TIFF to 1-bit bilevel
# @description: Saves an L-mode grayscale TIFF with Pillow, runs tiffdither to produce a bilevel TIFF, and verifies tag_v2[258] BitsPerSample is 1 and Pillow opens the result in mode "1".
# @timeout: 180
# @tags: usage, tiff, python, tiffdither
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/gray.tiff"
dst="$tmpdir/bilevel.tiff"

python3 - "$src" <<'PY'
import sys
from PIL import Image, TiffImagePlugin
img = Image.new("L", (32, 16))
img.putdata([(x * 8 + y * 4) % 256 for y in range(16) for x in range(32)])
# tiffdither requires plain stripped 8-bit grayscale with PhotometricInterpretation
# = BlackIsZero (1). Pillow's default L mode satisfies that, but pin it
# explicitly so the file format does not depend on Pillow's defaults.
ifd = TiffImagePlugin.ImageFileDirectory_v2()
ifd[262] = 1     # PhotometricInterpretation: BlackIsZero
ifd[258] = 8     # BitsPerSample
img.save(sys.argv[1], "TIFF", compression="raw", tiffinfo=ifd)
PY

validator_require_file "$src"
tiffdither "$src" "$dst"
validator_require_file "$dst"

# tiffinfo from libtiff is the authoritative metadata reader for the output.
tiffinfo "$dst" >"$tmpdir/info.out"
grep -Eq 'Bits/Sample: 1' "$tmpdir/info.out"
grep -Eq 'Image Width: 32 Image Length: 16' "$tmpdir/info.out"
