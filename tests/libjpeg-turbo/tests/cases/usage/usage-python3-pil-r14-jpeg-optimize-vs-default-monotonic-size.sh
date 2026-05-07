#!/usr/bin/env bash
# @testcase: usage-python3-pil-r14-jpeg-optimize-vs-default-monotonic-size
# @title: Pillow JPEG save optimize=True yields a no-larger file than default
# @description: Saves the same Pillow image as JPEG twice — once with optimize=True and once without — and asserts the optimised output is no larger than the default output, exercising libjpeg-turbo's optimise-Huffman path through Pillow.
# @timeout: 60
# @tags: usage, jpeg, python, optimize
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
src = Image.new("RGB", (80, 60))
src.putdata([(((x * 5) ^ (y * 7)) & 255, (x * 3) & 255, (y * 11) & 255)
             for y in range(60) for x in range(80)])
src.save(base / "plain.jpg", "JPEG", quality=85)
src.save(base / "opt.jpg", "JPEG", quality=85, optimize=True)

a = (base / "plain.jpg").stat().st_size
b = (base / "opt.jpg").stat().st_size
assert a > 0 and b > 0
assert b <= a, f"expected optimize ({b}) <= plain ({a})"
PY
