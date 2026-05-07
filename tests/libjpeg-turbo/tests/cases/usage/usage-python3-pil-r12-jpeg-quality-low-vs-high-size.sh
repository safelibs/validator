#!/usr/bin/env bash
# @testcase: usage-python3-pil-r12-jpeg-quality-low-vs-high-size
# @title: Pillow JPEG save quality=10 yields a smaller file than quality=95
# @description: Saves the same Pillow image at quality=10 and quality=95 and asserts the low-quality file is strictly smaller, exercising the libjpeg-turbo lossy quality scale via Pillow's encoder.
# @timeout: 60
# @tags: usage, jpeg, python, quality
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import os, sys
from pathlib import Path
from PIL import Image

base = Path(sys.argv[1])
src = Image.new("RGB", (96, 64))
src.putdata([(((x * 7) ^ (y * 11)) & 255, (x * 5) & 255, (y * 3) & 255)
             for y in range(64) for x in range(96)])

src.save(base / "lo.jpg", "JPEG", quality=10)
src.save(base / "hi.jpg", "JPEG", quality=95)

lo = (base / "lo.jpg").stat().st_size
hi = (base / "hi.jpg").stat().st_size
assert lo > 0 and hi > 0, (lo, hi)
assert lo < hi, f"expected lo ({lo}) < hi ({hi})"
PY
