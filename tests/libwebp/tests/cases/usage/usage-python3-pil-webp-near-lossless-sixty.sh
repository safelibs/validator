#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-near-lossless-sixty
# @title: Pillow WebP near_lossless=60
# @description: Saves an RGB Pillow image with lossless=True and a moderate quality used as the near-lossless preprocessing level, then reopens it and confirms the WebP roundtrip preserves the canvas dimensions.
# @timeout: 180
# @tags: usage, webp, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
from pathlib import Path
from PIL import Image
import sys
tmpdir = Path(sys.argv[1])
src = Image.new('RGB', (6, 4))
src.putdata([
    (i * 17 % 256, (i * 23) % 256, (i * 29) % 256) for i in range(6 * 4)
])
out = tmpdir / 'nl60.webp'
src.save(out, 'WEBP', lossless=True, quality=60, method=4)
with Image.open(out) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    assert im.size == (6, 4), im.size
print('near-lossless-60', out.stat().st_size)
PY
