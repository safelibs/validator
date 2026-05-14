#!/usr/bin/env bash
# @testcase: usage-python3-pil-r17-jpeg-progressive-true-decodable
# @title: Pillow JPEG save progressive=True writes a JPEG that re-decodes to the original mode and size
# @description: Saves a 48x32 RGB image via Pillow with progressive=True and asserts the output is a JPEG that re-decodes as RGB with the original dimensions, exercising libjpeg-turbo's progressive encoder path through Pillow's progressive keyword (a decode-the-encoded round-trip distinct from SOF2-marker tests).
# @timeout: 60
# @tags: usage, jpeg, python, progressive
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
out = base / "prog.jpg"
src = Image.new("RGB", (48, 32))
src.putdata([((x * 11) & 255, (y * 13) & 255, ((x + y) * 17) & 255)
             for y in range(32) for x in range(48)])
src.save(out, "JPEG", quality=80, progressive=True)

with Image.open(out) as im:
    im.load()
    assert im.format == "JPEG", im.format
    assert im.mode == "RGB", im.mode
    assert im.size == (48, 32), im.size
PY
