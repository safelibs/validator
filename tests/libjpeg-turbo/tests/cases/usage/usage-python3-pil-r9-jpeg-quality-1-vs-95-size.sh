#!/usr/bin/env bash
# @testcase: usage-python3-pil-r9-jpeg-quality-1-vs-95-size
# @title: Pillow JPEG q=1 smaller than q=95
# @description: Saves the same source image at JPEG quality 1 and 95 with Pillow and verifies q=1 produces a strictly smaller file than q=95.
# @timeout: 180
# @tags: usage, jpeg, python, quality
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import os, random, sys
from PIL import Image

random.seed(1234)
w, h = 64, 64
data = bytes(random.randint(0, 255) for _ in range(w * h * 3))
im = Image.frombytes("RGB", (w, h), data)

p1 = sys.argv[1] + "/q1.jpg"
p95 = sys.argv[1] + "/q95.jpg"

im.save(p1, "JPEG", quality=1)
im.save(p95, "JPEG", quality=95)

s1 = os.path.getsize(p1)
s95 = os.path.getsize(p95)
assert s1 < s95, (s1, s95)
print("ok", s1, s95)
PY
