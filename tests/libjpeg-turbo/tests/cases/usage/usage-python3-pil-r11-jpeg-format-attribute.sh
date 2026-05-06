#!/usr/bin/env bash
# @testcase: usage-python3-pil-r11-jpeg-format-attribute
# @title: Pillow reports format=JPEG after opening a saved JPEG
# @description: Saves a synthetic RGB image with Pillow as JPEG, reopens it, and asserts that Image.format equals "JPEG" — confirming the JpegImagePlugin probe correctly identifies the file by its SOI marker rather than its filename suffix.
# @timeout: 60
# @tags: usage, jpeg, python, format
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import sys
from PIL import Image

out = sys.argv[1] + "/probe.dat"
src = Image.new("RGB", (40, 30))
src.putdata([(i & 255, (i * 3) & 255, (i * 7) & 255) for i in range(40 * 30)])
src.save(out, "JPEG", quality=80)

with Image.open(out) as im:
    im.load()
    assert im.format == "JPEG", im.format
    assert im.size == (40, 30), im.size
    assert im.mode == "RGB", im.mode
PY
