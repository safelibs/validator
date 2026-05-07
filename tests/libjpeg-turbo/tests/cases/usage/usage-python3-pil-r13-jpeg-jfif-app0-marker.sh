#!/usr/bin/env bash
# @testcase: usage-python3-pil-r13-jpeg-jfif-app0-marker
# @title: Pillow JPEG default save emits a JFIF APP0 segment
# @description: Saves a default RGB JPEG via Pillow and asserts the encoded byte stream contains the APP0 marker (FFE0) followed by the "JFIF" identifier, exercising libjpeg-turbo's default JFIF header writer.
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
out = base / "jfif.jpg"
src = Image.new("RGB", (16, 12), (120, 60, 200))
src.save(out, "JPEG", quality=80)

data = out.read_bytes()
assert data[:2] == b"\xff\xd8", data[:2].hex()
i = data.find(b"\xff\xe0")
assert i >= 0, "missing APP0 marker"
# JFIF identifier is "JFIF\x00" right after segment length (4 bytes in).
assert data[i + 4:i + 9] == b"JFIF\x00", data[i + 4:i + 9]

with Image.open(out) as im:
    im.load()
    assert im.format == "JPEG", im.format
    assert im.info.get("jfif") in (0x101, 0x102, 257, 258), im.info.get("jfif")
PY
