#!/usr/bin/env bash
# @testcase: usage-python3-pil-r13-jpeg-cmyk-four-components
# @title: Pillow JPEG save of a CMYK image writes a 4-component SOF marker
# @description: Builds a CMYK Pillow image, saves as JPEG, and parses the SOF marker to confirm Nf == 4 components, exercising the libjpeg-turbo 4-channel CMYK encode path.
# @timeout: 60
# @tags: usage, jpeg, python, cmyk
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
out = base / "cmyk.jpg"
src = Image.new("CMYK", (32, 24))
src.putdata([((x * 7) & 255, (y * 11) & 255, ((x + y) * 5) & 255, (x * y) & 255)
             for y in range(24) for x in range(32)])
src.save(out, "JPEG", quality=85)

data = out.read_bytes()
# SOF0 (FFC0) is the baseline marker; CMYK is encoded via SOF0 with 4 components.
i = data.find(b"\xff\xc0")
if i < 0:
    # Some CMYK paths may emit SOF2 progressive — accept either.
    i = data.find(b"\xff\xc2")
assert i > 0, "no SOF marker in CMYK JPEG"
nf = data[i + 9]
assert nf == 4, f"expected 4 components, got {nf}"

with Image.open(out) as im:
    im.load()
    assert im.format == "JPEG", im.format
    assert im.mode == "CMYK", im.mode
    assert im.size == (32, 24), im.size
PY
