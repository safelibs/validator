#!/usr/bin/env bash
# @testcase: usage-python3-pil-r10-jpeg-soi-eoi-markers
# @title: Pillow JPEG byte stream begins with SOI and ends with EOI
# @description: Saves a JPEG via Pillow and validates the byte stream framing: opens with FFD8 (SOI) and the trailing two bytes are FFD9 (EOI).
# @timeout: 180
# @tags: usage, jpeg, python, encoder
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
out = base / "framed.jpg"
src = Image.new("RGB", (40, 30))
src.putdata([(((x * 3) ^ (y * 5)) & 255, (x * 2) & 255, (y * 4) & 255)
             for y in range(30) for x in range(40)])
src.save(out, "JPEG", quality=78)

data = out.read_bytes()
assert data[:2] == b"\xff\xd8", f"SOI mismatch: {data[:2].hex()}"
assert data[-2:] == b"\xff\xd9", f"EOI mismatch: {data[-2:].hex()}"
# Sanity: minimum plausible JPEG size for this content.
assert len(data) > 64, len(data)
print("framing-ok", len(data))
PY
