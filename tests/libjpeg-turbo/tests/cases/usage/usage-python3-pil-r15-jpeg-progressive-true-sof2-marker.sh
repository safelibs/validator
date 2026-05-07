#!/usr/bin/env bash
# @testcase: usage-python3-pil-r15-jpeg-progressive-true-sof2-marker
# @title: Pillow JPEG save progressive=True writes an SOF2 (FFC2) marker with no SOF0
# @description: Saves an RGB JPEG via Pillow with progressive=True and confirms the encoded byte stream contains the FFC2 SOF2 marker but no FFC0 SOF0 marker, exercising libjpeg-turbo's progressive Huffman encoder path through Pillow.
# @timeout: 60
# @tags: usage, jpeg, python, progressive
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
src = Image.new("RGB", (40, 30))
src.putdata([((x * 7) & 255, (y * 11) & 255, ((x ^ y) * 5) & 255)
             for y in range(30) for x in range(40)])
src.save(out, "JPEG", quality=85, progressive=True)

data = out.read_bytes()
assert data[:2] == b"\xff\xd8", data[:2].hex()
assert b"\xff\xc2" in data, "missing SOF2 marker for progressive JPEG"
assert b"\xff\xc0" not in data, "unexpected SOF0 marker in progressive JPEG"
PY
