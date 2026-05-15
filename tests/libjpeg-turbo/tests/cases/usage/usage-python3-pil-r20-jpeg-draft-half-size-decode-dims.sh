#!/usr/bin/env bash
# @testcase: usage-python3-pil-r20-jpeg-draft-half-size-decode-dims
# @title: Pillow JPEG draft("RGB", (32,32)) on a 64x64 source halves the decoded dims
# @description: Saves a 64x64 RGB JPEG, reopens it, calls im.draft("RGB", (32,32)) before im.load(), and asserts the resulting size is (32,32) (libjpeg-turbo's DCT scale-by-half decode path), exercising the draft-mode size-scaling decode invocation through Pillow.
# @timeout: 120
# @tags: usage, jpeg, python, draft, scale, r20
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
out = base / "src.jpg"
W, H = 64, 64
src = Image.new("RGB", (W, H))
src.putdata([(((x + y) * 9) & 255, (x * 5) & 255, (y * 11) & 255)
             for y in range(H) for x in range(W)])
src.save(out, "JPEG", quality=90)

with Image.open(out) as im:
    im.draft("RGB", (32, 32))
    im.load()
    assert im.size == (32, 32), im.size
    assert im.mode == "RGB", im.mode
PY
