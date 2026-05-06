#!/usr/bin/env bash
# @testcase: usage-python3-pil-r9-jpeg-rotate-90-dimensions
# @title: Pillow rotate JPEG 90 swaps dimensions
# @description: Rotates a non-square JPEG by 90 degrees with expand=True and verifies the resulting image dimensions are swapped.
# @timeout: 180
# @tags: usage, jpeg, python, rotate
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import sys
from PIL import Image

base = sys.argv[1] + "/in.jpg"
rot  = sys.argv[1] + "/rot.jpg"

im = Image.new("RGB", (12, 4), (255, 0, 0))
im.save(base, "JPEG")

with Image.open(base) as src:
    out = src.rotate(90, expand=True)
    out.save(rot, "JPEG")

with Image.open(rot) as probe:
    assert probe.size == (4, 12), probe.size
print("ok", probe.size)
PY
