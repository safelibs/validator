#!/usr/bin/env bash
# @testcase: usage-python3-pil-r14-jpeg-l-mode-sof-one-component
# @title: Pillow JPEG save of an L-mode image writes a 1-component SOF marker
# @description: Builds a Pillow L-mode (grayscale) image, saves as JPEG, and parses the SOF marker to confirm Nf == 1 component, exercising the libjpeg-turbo Y-only single-channel encode path.
# @timeout: 60
# @tags: usage, jpeg, python, grayscale
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
out = base / "l.jpg"
src = Image.new("L", (32, 24))
src.putdata([(x * 7 + y * 11) & 0xff for y in range(24) for x in range(32)])
src.save(out, "JPEG", quality=85)

data = out.read_bytes()
i = data.find(b"\xff\xc0")
if i < 0:
    i = data.find(b"\xff\xc2")
assert i > 0, "no SOF marker"
nf = data[i + 9]
assert nf == 1, f"expected 1 component for L-mode, got {nf}"

with Image.open(out) as im:
    im.load()
    assert im.format == "JPEG", im.format
    assert im.mode == "L", im.mode
    assert im.size == (32, 24), im.size
PY
