#!/usr/bin/env bash
# @testcase: usage-python3-pil-r16-webp-open-getexif-no-tags
# @title: Pillow WebP getexif on an image saved without EXIF returns an empty Exif container
# @description: Saves a small RGB image as WEBP via Pillow with no EXIF supplied, re-opens the file, and asserts Image.getexif() returns a Pillow Exif object whose length is zero — confirming libwebp's optional EXIF chunk stays absent unless explicitly written.
# @timeout: 60
# @tags: usage, python3-pil, webp, exif
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/out.webp" <<'PY'
import sys
from PIL import Image

img = Image.new('RGB', (24, 24), (80, 120, 160))
img.save(sys.argv[1], 'WEBP', quality=80)

with Image.open(sys.argv[1]) as im:
    im.load()
    exif = im.getexif()
    # Pillow returns an Exif (Image.Exif) instance; len == 0 means no tags.
    from PIL.Image import Exif
    assert isinstance(exif, Exif), type(exif)
    assert len(exif) == 0, dict(exif)
PY
