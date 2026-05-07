#!/usr/bin/env bash
# @testcase: usage-python3-pil-r15-jpeg-comment-roundtrip-info
# @title: Pillow JPEG save comment= round-trips through im.info["comment"]
# @description: Saves an RGB JPEG via Pillow with comment=b"hello-r15" and re-opens to confirm im.info["comment"] equals the original bytes, exercising libjpeg-turbo's COM segment writer/reader through Pillow.
# @timeout: 60
# @tags: usage, jpeg, python, comment
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
out = base / "com.jpg"
src = Image.new("RGB", (24, 18), (90, 180, 60))
src.save(out, "JPEG", quality=85, comment=b"hello-r15")

with Image.open(out) as im:
    im.load()
    assert im.format == "JPEG", im.format
    c = im.info.get("comment")
    assert c == b"hello-r15", c
PY
