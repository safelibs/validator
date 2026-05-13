#!/usr/bin/env bash
# @testcase: usage-python3-pil-r16-jpeg-thumbnail-shrinks-bytes
# @title: Pillow Image.thumbnail then JPEG save yields a smaller file than the source JPEG
# @description: Saves a 256x192 RGB image as JPEG, opens it, calls im.thumbnail((64,48)), saves the resized image to a new JPEG, and asserts the thumbnail's byte size is strictly less than the source JPEG byte size and dimensions are no larger than the requested bounds.
# @timeout: 60
# @tags: usage, jpeg, python, thumbnail
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
src_path = base / "src.jpg"
thumb_path = base / "thumb.jpg"

src = Image.new("RGB", (256, 192))
src.putdata([(((x * 5) ^ (y * 3)) & 255,
              ((x * 7) ^ (y * 9)) & 255,
              ((x * 11) ^ (y * 13)) & 255)
             for y in range(192) for x in range(256)])
src.save(src_path, "JPEG", quality=85)

with Image.open(src_path) as im:
    im.load()
    im.thumbnail((64, 48))
    assert im.size[0] <= 64 and im.size[1] <= 48, im.size
    im.save(thumb_path, "JPEG", quality=85)

s_src = src_path.stat().st_size
s_thumb = thumb_path.stat().st_size
assert s_thumb < s_src, f"expected thumb ({s_thumb}) < src ({s_src})"

with Image.open(thumb_path) as im:
    im.load()
    assert im.format == "JPEG"
PY
