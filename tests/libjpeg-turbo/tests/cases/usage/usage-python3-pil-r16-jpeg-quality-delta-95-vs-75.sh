#!/usr/bin/env bash
# @testcase: usage-python3-pil-r16-jpeg-quality-delta-95-vs-75
# @title: Pillow JPEG save quality=95 yields a strictly larger file than quality=75
# @description: Saves the same RGB image via Pillow at quality=75 and quality=95 and asserts the quality-95 file is strictly larger than the quality-75 file, exercising libjpeg-turbo's quantisation table scaling through Pillow's quality keyword.
# @timeout: 60
# @tags: usage, jpeg, python, quality
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
src = Image.new("RGB", (96, 72))
src.putdata([((x * 13) & 255, (y * 17) & 255, ((x + y) * 7) & 255)
             for y in range(72) for x in range(96)])

p75 = base / "q75.jpg"
p95 = base / "q95.jpg"
src.save(p75, "JPEG", quality=75)
src.save(p95, "JPEG", quality=95)

s75 = p75.stat().st_size
s95 = p95.stat().st_size
assert s95 > s75, f"expected q95 ({s95}) > q75 ({s75})"

for p in (p75, p95):
    with Image.open(p) as im:
        im.load()
        assert im.format == "JPEG"
PY
