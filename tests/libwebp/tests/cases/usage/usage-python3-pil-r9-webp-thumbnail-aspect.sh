#!/usr/bin/env bash
# @testcase: usage-python3-pil-r9-webp-thumbnail-aspect
# @title: Pillow WebP thumbnail preserves aspect ratio
# @description: Loads a 200x100 generated RGB image, encodes it as WebP, decodes, calls Image.thumbnail((50,50)) and asserts the thumbnail is 50x25.
# @timeout: 180
# @tags: usage, python3-pil, webp
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.webp"
import sys
from PIL import Image
src = Image.new('RGB', (200, 100), (123, 45, 67))
src.save(sys.argv[1], 'WEBP', quality=85)
PY

python3 - <<'PY' "$tmpdir/in.webp"
import sys
from PIL import Image
with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.size == (200, 100), im.size
    im.thumbnail((50, 50))
    assert im.size == (50, 25), im.size
PY
