#!/usr/bin/env bash
# @testcase: usage-python3-pil-r9-jpeg-getpixel-roundtrip
# @title: Pillow getpixel on solid JPEG
# @description: Encodes a uniformly-colored JPEG at high quality and confirms getpixel returns a pixel within tolerance of the encoded color.
# @timeout: 180
# @tags: usage, jpeg, python, pixel
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import sys
from PIL import Image

out = sys.argv[1] + "/solid.jpg"
target = (200, 100, 50)
im = Image.new("RGB", (16, 16), target)
im.save(out, "JPEG", quality=95)

with Image.open(out) as probe:
    probe.load()
    p = probe.getpixel((8, 8))
    assert isinstance(p, tuple) and len(p) == 3, p
    for got, want in zip(p, target):
        assert abs(got - want) < 12, (p, target)
print("ok", p)
PY
