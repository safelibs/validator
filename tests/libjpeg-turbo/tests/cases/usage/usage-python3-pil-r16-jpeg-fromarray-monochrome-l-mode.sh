#!/usr/bin/env bash
# @testcase: usage-python3-pil-r16-jpeg-fromarray-monochrome-l-mode
# @title: Pillow Image.frombytes mode "L" saves a single-component JPEG re-read in mode L
# @description: Builds a 32x24 grayscale buffer with Pillow's frombytes for mode "L", saves as JPEG, and asserts the re-decoded image has format=JPEG and mode=L (single-component / one-band) with the original dimensions, exercising libjpeg-turbo's grayscale-only encode and decode paths through Pillow.
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
out = base / "gray.jpg"

W, H = 32, 24
buf = bytes([(x * 7 + y * 11) & 255 for y in range(H) for x in range(W)])
src = Image.frombytes("L", (W, H), buf)
src.save(out, "JPEG", quality=85)

with Image.open(out) as im:
    im.load()
    assert im.format == "JPEG", im.format
    assert im.mode == "L", im.mode
    assert im.size == (W, H), im.size
PY
