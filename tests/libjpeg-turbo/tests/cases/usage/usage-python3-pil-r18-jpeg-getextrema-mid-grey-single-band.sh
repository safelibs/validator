#!/usr/bin/env bash
# @testcase: usage-python3-pil-r18-jpeg-getextrema-mid-grey-single-band
# @title: Pillow getextrema on a solid-127 grayscale JPEG returns a near-127 tight range
# @description: Saves a 24x24 mode-L grayscale JPEG filled with byte 127 via Pillow at quality=95, reopens it, and asserts getextrema() returns a single tuple (min, max) where both values lie in [120, 134] (libjpeg-turbo quantisation drift around the original 127), exercising Pillow's getextrema reflection through libjpeg-turbo grayscale decode.
# @timeout: 60
# @tags: usage, jpeg, python, getextrema, grayscale, r18
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import sys
from pathlib import Path
from PIL import Image

base = Path(sys.argv[1])
out = base / "grey.jpg"
W, H = 24, 24
src = Image.new("L", (W, H), color=127)
src.save(out, "JPEG", quality=95)

with Image.open(out) as im:
    im.load()
    assert im.mode == "L", im.mode
    extr = im.getextrema()
    # mode L returns a single tuple (min, max), not a tuple of tuples
    assert isinstance(extr, tuple) and len(extr) == 2, extr
    lo, hi = extr
    assert 120 <= lo <= hi <= 134, (lo, hi)
PY
