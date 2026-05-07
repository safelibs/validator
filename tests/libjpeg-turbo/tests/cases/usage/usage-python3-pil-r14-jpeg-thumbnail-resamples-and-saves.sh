#!/usr/bin/env bash
# @testcase: usage-python3-pil-r14-jpeg-thumbnail-resamples-and-saves
# @title: Pillow Image.thumbnail then JPEG save shrinks geometry below the cap
# @description: Loads a 96x72 RGB JPEG, calls Image.thumbnail((48, 48)) (which preserves aspect ratio while capping each axis), saves the result as JPEG, and asserts the reloaded image has width<=48 and height<=48 with both dimensions strictly less than the source, exercising the Pillow resample-then-encode pipeline.
# @timeout: 60
# @tags: usage, jpeg, python, thumbnail
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
src_path = base / "src.jpg"
out_path = base / "thumb.jpg"

src = Image.new("RGB", (96, 72))
src.putdata([((x * 5) & 255, (y * 7) & 255, ((x + y) * 3) & 255)
             for y in range(72) for x in range(96)])
src.save(src_path, "JPEG", quality=85)

with Image.open(src_path) as im:
    im.thumbnail((48, 48))
    assert im.size[0] <= 48 and im.size[1] <= 48, im.size
    assert im.size[0] < 96 and im.size[1] < 72, im.size
    im.save(out_path, "JPEG", quality=85)

with Image.open(out_path) as im2:
    im2.load()
    assert im2.format == "JPEG", im2.format
    assert im2.size[0] <= 48 and im2.size[1] <= 48, im2.size
PY
