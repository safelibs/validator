#!/usr/bin/env bash
# @testcase: usage-python3-pil-r16-jpeg-subsampling-keyword-422
# @title: Pillow JPEG save subsampling=1 (4:2:2) writes a decodable RGB image
# @description: Saves a small RGB JPEG via Pillow with subsampling=1 (4:2:2) and asserts the output is a JPEG that re-decodes as RGB with the original dimensions, exercising libjpeg-turbo's 4:2:2 chroma-subsampling encoder path through Pillow.
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
out = base / "s422.jpg"
src = Image.new("RGB", (32, 24))
src.putdata([((x * 9) & 255, (y * 11) & 255, ((x ^ y) * 13) & 255)
             for y in range(24) for x in range(32)])
src.save(out, "JPEG", quality=80, subsampling=1)

with Image.open(out) as im:
    im.load()
    assert im.format == "JPEG", im.format
    assert im.mode == "RGB", im.mode
    assert im.size == (32, 24), im.size
PY
