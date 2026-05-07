#!/usr/bin/env bash
# @testcase: usage-python3-pil-r13-jpeg-draft-half-load
# @title: Pillow JPEG draft mode shrinks a 64x32 image to no more than half size
# @description: Saves a 64x32 JPEG via Pillow then reopens with Image.draft("RGB", (32, 16)) before load() and asserts the loaded image's width and height are at most 32x16, exercising the libjpeg-turbo DCT-domain scale-down path.
# @timeout: 60
# @tags: usage, jpeg, python, decoder
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
out = base / "in.jpg"
src = Image.new("RGB", (64, 32))
src.putdata([((x * 7) & 255, (y * 11) & 255, ((x ^ y) * 5) & 255)
             for y in range(32) for x in range(64)])
src.save(out, "JPEG", quality=85)

with Image.open(out) as im:
    im.draft("RGB", (32, 16))
    im.load()
    # libjpeg-turbo only allows scaling by N/8 where N in 1..8; for 64x32 a
    # 32x16 hint typically yields exactly 32x16.
    assert im.format == "JPEG", im.format
    assert im.size[0] <= 32, im.size
    assert im.size[1] <= 16, im.size
    assert im.size[0] >= 8, im.size
    assert im.size[1] >= 4, im.size
PY
