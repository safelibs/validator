#!/usr/bin/env bash
# @testcase: usage-python3-pil-r18-jpeg-info-dpi-roundtrip-72-72
# @title: Pillow JPEG save dpi=(72,72) round-trips through info["dpi"]
# @description: Saves a small RGB JPEG via Pillow with dpi=(72,72), reopens it, and asserts im.info["dpi"] equals (72, 72) (round-tripped through the JFIF APP0 density fields), exercising libjpeg-turbo's JFIF marker writing with explicit DPI distinct from the r15 (150,150) coverage.
# @timeout: 60
# @tags: usage, jpeg, python, dpi, jfif, r18
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
out = base / "dpi72.jpg"
W, H = 32, 20
src = Image.new("RGB", (W, H))
src.putdata([((x * 5) & 255, (y * 7) & 255, ((x + y) * 11) & 255)
             for y in range(H) for x in range(W)])
src.save(out, "JPEG", quality=85, dpi=(72, 72))

with Image.open(out) as im:
    im.load()
    dpi = im.info.get("dpi")
    assert dpi is not None, "no dpi info"
    # Compare integer-valued tuple
    assert tuple(int(v) for v in dpi) == (72, 72), dpi
PY
