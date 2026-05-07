#!/usr/bin/env bash
# @testcase: usage-python3-pil-r12-jpeg-optimize-shrinks-output
# @title: Pillow JPEG save optimize=True is no larger than the unoptimized save
# @description: Saves the same Pillow image twice at quality=80 with optimize=True and optimize=False, and asserts the optimized output is no larger than the unoptimized one (and both are valid JPEGs).
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
src.putdata([(((x * 13) ^ (y * 7)) & 255, (x * 11) & 255, (y * 5) & 255)
             for y in range(60) for x in range(80)])

src.save(base / "no.jpg", "JPEG", quality=80, optimize=False)
src.save(base / "yes.jpg", "JPEG", quality=80, optimize=True)

no  = (base / "no.jpg").stat().st_size
yes = (base / "yes.jpg").stat().st_size
assert no > 0 and yes > 0, (no, yes)
# optimize=True builds a custom Huffman table; never larger than default.
assert yes <= no, f"optimize=True grew file: {yes} > {no}"

# Both must reload as JPEG.
for name in ("no.jpg", "yes.jpg"):
    with Image.open(base / name) as im:
        im.load()
        assert im.format == "JPEG", (name, im.format)
PY
