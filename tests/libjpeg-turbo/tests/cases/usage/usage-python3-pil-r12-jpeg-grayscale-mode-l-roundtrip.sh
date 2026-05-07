#!/usr/bin/env bash
# @testcase: usage-python3-pil-r12-jpeg-grayscale-mode-l-roundtrip
# @title: Pillow JPEG save of an L-mode image reloads as L-mode JPEG
# @description: Builds an 8-bit grayscale (L-mode) Pillow image, saves it as JPEG, and reopens to confirm the reloaded image still reports mode == "L" and the SOF marker advertises a single component.
# @timeout: 60
# @tags: usage, jpeg, python, grayscale
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
out = base / "gray.jpg"
src = Image.new("L", (32, 24))
src.putdata([((x * 7) ^ (y * 11)) & 255 for y in range(24) for x in range(32)])
src.save(out, "JPEG", quality=80)

with Image.open(out) as im:
    im.load()
    assert im.format == "JPEG", im.format
    assert im.mode == "L", im.mode
    assert im.size == (32, 24), im.size

# SOF0 marker (FFC0) Nf field should be 1 component for grayscale.
data = out.read_bytes()
i = data.find(b"\xff\xc0")
assert i > 0, "no SOF0 marker"
nf = data[i + 9]
assert nf == 1, f"expected 1 component, got {nf}"
PY
