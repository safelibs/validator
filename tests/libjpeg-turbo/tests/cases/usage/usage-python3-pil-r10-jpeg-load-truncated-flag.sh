#!/usr/bin/env bash
# @testcase: usage-python3-pil-r10-jpeg-load-truncated-flag
# @title: Pillow LOAD_TRUNCATED_IMAGES decodes a truncated JPEG
# @description: Saves a JPEG, drops the trailing bytes (no EOI), then decodes once with ImageFile.LOAD_TRUNCATED_IMAGES=True and once without. The flagged decode succeeds and produces an image with the expected dimensions; the unflagged decode raises OSError.
# @timeout: 180
# @tags: usage, jpeg, python, decoder
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import sys
from pathlib import Path
from PIL import Image, ImageFile

base = Path(sys.argv[1])
full = base / "full.jpg"
trunc = base / "trunc.jpg"

src = Image.new("RGB", (96, 72))
src.putdata([((x * 5) & 255, (y * 9) & 255, ((x ^ y) * 3) & 255)
             for y in range(72) for x in range(96)])
src.save(full, "JPEG", quality=80)

data = full.read_bytes()
# Drop the trailing 256 bytes so the EOI marker is gone.
trunc.write_bytes(data[:-256])

ImageFile.LOAD_TRUNCATED_IMAGES = False
strict_failed = False
try:
    with Image.open(trunc) as im:
        im.load()
except OSError:
    strict_failed = True
assert strict_failed, "strict decode should have failed"

ImageFile.LOAD_TRUNCATED_IMAGES = True
try:
    with Image.open(trunc) as im:
        im.load()
        assert im.size == (96, 72), im.size
        assert im.format == "JPEG"
finally:
    ImageFile.LOAD_TRUNCATED_IMAGES = False

print("truncated-decode-ok")
PY
