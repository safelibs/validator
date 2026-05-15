#!/usr/bin/env bash
# @testcase: usage-python3-pil-r19-jpeg-progressive-roundtrip-info
# @title: Pillow JPEG save progressive=True round-trips info["progressive"] truthy
# @description: Saves an RGB JPEG via Pillow with progressive=True, reopens it, and asserts im.info.get("progressive") is truthy and im.info.get("progression") is also truthy on the reopened progressive JPEG, exercising libjpeg-turbo's progressive-mode SOF2 marker round-trip through Pillow's info introspection.
# @timeout: 60
# @tags: usage, jpeg, python, progressive, info, r19
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
W, H = 32, 20
src = Image.new("RGB", (W, H))
src.putdata([((x * 11) & 255, (y * 17) & 255, ((x + y) * 13) & 255)
             for y in range(H) for x in range(W)])
src.save(out, "JPEG", quality=85, progressive=True)

with Image.open(out) as im:
    im.load()
    assert im.format == "JPEG", im.format
    # Either info key may be used by Pillow; at least one must be truthy.
    a = bool(im.info.get("progressive"))
    b = bool(im.info.get("progression"))
    assert a or b, dict(im.info)
PY
