#!/usr/bin/env bash
# @testcase: usage-python3-pil-r18-jpeg-quality-keyword-1-vs-95-monotonic
# @title: Pillow JPEG save quality=1 produces a strictly smaller file than quality=95
# @description: Saves the same 48x32 RGB image twice via Pillow, once with quality=1 and once with quality=95, and asserts the quality=1 file is strictly smaller in bytes than the quality=95 file, exercising libjpeg-turbo's quantisation-table scaling through Pillow's quality keyword (a different size-pair than r9 1-vs-95 which only checked strict size monotonicity at the same dims).
# @timeout: 60
# @tags: usage, jpeg, python, quality, monotonic, r18
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
W, H = 48, 32
src = Image.new("RGB", (W, H))
src.putdata([((x * 31) & 255, (y * 37) & 255, ((x + y) * 41) & 255)
             for y in range(H) for x in range(W)])
low = base / "q1.jpg"
high = base / "q95.jpg"
src.save(low, "JPEG", quality=1)
src.save(high, "JPEG", quality=95)

s_low = low.stat().st_size
s_high = high.stat().st_size
assert s_low < s_high, (s_low, s_high)
# Both must still be valid JPEGs that decode at the original dims.
for p in (low, high):
    with Image.open(p) as im:
        im.load()
        assert im.format == "JPEG", (p, im.format)
        assert im.size == (W, H), (p, im.size)
PY
