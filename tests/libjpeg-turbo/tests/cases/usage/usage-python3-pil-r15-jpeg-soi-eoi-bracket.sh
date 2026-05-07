#!/usr/bin/env bash
# @testcase: usage-python3-pil-r15-jpeg-soi-eoi-bracket
# @title: Pillow JPEG save begins with SOI (FFD8) and ends with EOI (FFD9)
# @description: Saves an RGB JPEG via Pillow at quality=85 and asserts the encoded byte stream begins with the FFD8 SOI marker and ends with the FFD9 EOI marker, exercising the libjpeg-turbo stream-bracketing invariant.
# @timeout: 60
# @tags: usage, jpeg, python, structure
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
out = base / "bracket.jpg"
src = Image.new("RGB", (32, 24))
src.putdata([((x * 5) & 255, (y * 7) & 255, ((x + y) * 3) & 255)
             for y in range(24) for x in range(32)])
src.save(out, "JPEG", quality=85)

data = out.read_bytes()
assert len(data) >= 4, len(data)
assert data[:2] == b"\xff\xd8", data[:2].hex()
assert data[-2:] == b"\xff\xd9", data[-2:].hex()
PY
