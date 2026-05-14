#!/usr/bin/env bash
# @testcase: usage-python3-pil-r17-jpeg-subsampling-zero-444
# @title: Pillow JPEG save subsampling=0 (4:4:4) writes a decodable RGB image
# @description: Saves a small RGB JPEG via Pillow with subsampling=0 (4:4:4 — no chroma decimation) and asserts the output is a JPEG that re-decodes as RGB with the original dimensions, exercising libjpeg-turbo's 4:4:4 chroma path through Pillow's subsampling keyword (distinct from the r16 4:2:2 subsampling=1 test).
# @timeout: 60
# @tags: usage, jpeg, python, subsampling
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
out = base / "s444.jpg"
src = Image.new("RGB", (40, 24))
src.putdata([((x * 7) & 255, (y * 9) & 255, ((x ^ y) * 11) & 255)
             for y in range(24) for x in range(40)])
src.save(out, "JPEG", quality=85, subsampling=0)

with Image.open(out) as im:
    im.load()
    assert im.format == "JPEG", im.format
    assert im.mode == "RGB", im.mode
    assert im.size == (40, 24), im.size
PY
