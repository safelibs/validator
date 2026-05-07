#!/usr/bin/env bash
# @testcase: usage-python3-pil-r12-jpeg-progressive-marker-sof2
# @title: Pillow JPEG progressive=True writes an SOF2 (FFC2) marker
# @description: Saves a JPEG with Pillow progressive=True and confirms the byte stream contains an SOF2 (FFC2) marker (progressive-mode start-of-frame) and not the SOF0 (FFC0) baseline marker.
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
src = Image.new("RGB", (40, 32))
src.putdata([((x * 9) & 255, (y * 11) & 255, ((x ^ y) * 5) & 255)
             for y in range(32) for x in range(40)])
src.save(out, "JPEG", quality=80, progressive=True)

data = out.read_bytes()
assert data[:2] == b"\xff\xd8", f"missing SOI: {data[:2].hex()}"
assert b"\xff\xc2" in data, "missing SOF2 (progressive) marker"
assert b"\xff\xc0" not in data, "unexpected SOF0 (baseline) marker in progressive image"
PY
