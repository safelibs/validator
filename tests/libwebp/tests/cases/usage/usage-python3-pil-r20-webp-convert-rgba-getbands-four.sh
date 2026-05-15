#!/usr/bin/env bash
# @testcase: usage-python3-pil-r20-webp-convert-rgba-getbands-four
# @title: Pillow opens an RGBA WEBP and reports four bands ('R','G','B','A')
# @description: Saves an RGBA image to WEBP via Pillow with lossless=True, reopens with Image.open, calls load(), and asserts getbands() returns the four-tuple ('R','G','B','A') — pinning libwebp's alpha-preserving decode through PIL.
# @timeout: 60
# @tags: usage, python3-pil, webp, rgba, getbands, r20
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/out.webp" <<'PY'
import sys
from PIL import Image

img = Image.new('RGBA', (24, 18), (10, 80, 160, 200))
img.save(sys.argv[1], 'WEBP', lossless=True)

with Image.open(sys.argv[1]) as out:
    out.load()
    bands = out.getbands()
    assert bands == ('R', 'G', 'B', 'A'), bands
PY
