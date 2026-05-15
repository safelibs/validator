#!/usr/bin/env bash
# @testcase: usage-python3-pil-r20-jpeg-save-optimize-no-larger
# @title: Pillow JPEG save with optimize=True is not larger than save without optimize
# @description: Saves the same RGB image as JPEG at quality=85 twice — once with optimize=False and once with optimize=True — and asserts the optimized file size is less than or equal to the unoptimized size, exercising libjpeg-turbo's optimized Huffman table generation path through Pillow's optimize flag.
# @timeout: 120
# @tags: usage, jpeg, python, optimize, size, r20
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
W, H = 96, 64
src = Image.new("RGB", (W, H))
src.putdata([((x * 13) & 255, (y * 7) & 255, ((x ^ y) * 5) & 255)
             for y in range(H) for x in range(W)])

plain = base / "plain.jpg"
opt = base / "opt.jpg"
src.save(plain, "JPEG", quality=85, optimize=False)
src.save(opt, "JPEG", quality=85, optimize=True)

s_plain = plain.stat().st_size
s_opt = opt.stat().st_size
assert s_opt <= s_plain, (s_opt, s_plain)
PY
