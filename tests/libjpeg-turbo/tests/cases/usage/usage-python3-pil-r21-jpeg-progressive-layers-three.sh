#!/usr/bin/env bash
# @testcase: usage-python3-pil-r21-jpeg-progressive-layers-three
# @title: Pillow opens a progressive RGB JPEG and reports im.layers == 3
# @description: Encodes a 40x32 RGB image as a progressive JPEG via Pillow, re-opens it, and asserts the JpegImageFile attribute "layers" equals 3 (one per RGB component) and the info["progressive"] flag is truthy - locking in libjpeg-turbo's per-component layer accounting reported on progressive decoder open, a property not previously asserted.
# @timeout: 120
# @tags: usage, jpeg, python, progressive, layers, r21
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
src = Image.new("RGB", (40, 32))
src.putdata([((x * 7) & 255, (y * 11) & 255, ((x ^ y) * 5) & 255)
             for y in range(32) for x in range(40)])
src.save(out, "JPEG", quality=85, progressive=True)

with Image.open(out) as im:
    assert im.mode == "RGB", im.mode
    assert im.info.get("progressive"), im.info
    layers = getattr(im, "layers", None)
    assert layers == 3, ("expected 3 layers, got", layers)
PY
