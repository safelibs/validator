#!/usr/bin/env bash
# @testcase: usage-python3-pil-r14-jpeg-quality-95-jfif-app0-marker
# @title: Pillow JPEG save quality=95 emits a JFIF APP0 marker
# @description: Saves an RGB JPEG via Pillow at quality=95 and confirms the encoded byte stream contains the FFE0 APP0 marker followed by the literal "JFIF\0" identifier, exercising libjpeg-turbo's JFIF header writer at high quality.
# @timeout: 60
# @tags: usage, jpeg, python, headers
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
out = base / "q95.jpg"
src = Image.new("RGB", (24, 18), (160, 80, 200))
src.save(out, "JPEG", quality=95)

data = out.read_bytes()
assert data[:2] == b"\xff\xd8", data[:2].hex()
i = data.find(b"\xff\xe0")
assert i >= 0, "missing APP0 marker"
assert data[i + 4:i + 9] == b"JFIF\x00", data[i + 4:i + 9]
PY
