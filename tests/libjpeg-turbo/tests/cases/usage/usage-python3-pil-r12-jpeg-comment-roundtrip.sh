#!/usr/bin/env bash
# @testcase: usage-python3-pil-r12-jpeg-comment-roundtrip
# @title: Pillow JPEG comment= argument round-trips through info["comment"]
# @description: Saves a JPEG with a custom comment via Pillow's comment= argument and reopens to confirm im.info["comment"] equals the same bytes, exercising the COM (FFFE) marker writer and reader.
# @timeout: 60
# @tags: usage, jpeg, python, metadata
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
src = Image.new("RGB", (24, 16))
src.putdata([((x * 9) & 255, (y * 11) & 255, ((x ^ y) * 3) & 255)
             for y in range(16) for x in range(24)])
marker = b"safelibs-r12-comment"
src.save(out, "JPEG", quality=80, comment=marker)

with Image.open(out) as im:
    im.load()
    got = im.info.get("comment")
    assert got == marker, (got, marker)
PY
