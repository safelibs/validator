#!/usr/bin/env bash
# @testcase: usage-python3-pil-r15-jpeg-quality-zero-vs-default-monotonic-size
# @title: Pillow JPEG save quality=1 yields a strictly smaller file than quality=95
# @description: Saves the same Pillow image as JPEG twice — once at quality=1 and once at quality=95 — and asserts the q1 output is strictly smaller than the q95 output, exercising libjpeg-turbo's quality-driven byte-size monotonicity at the low extreme.
# @timeout: 60
# @tags: usage, jpeg, python, quality
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
src = Image.new("RGB", (96, 72))
src.putdata([(((x * 5) ^ (y * 7)) & 255, (x * 3) & 255, (y * 11) & 255)
             for y in range(72) for x in range(96)])
src.save(base / "q1.jpg", "JPEG", quality=1)
src.save(base / "q95.jpg", "JPEG", quality=95)

a = (base / "q1.jpg").stat().st_size
b = (base / "q95.jpg").stat().st_size
assert a > 0 and b > 0
assert a < b, f"expected q1 ({a}) < q95 ({b})"
PY
