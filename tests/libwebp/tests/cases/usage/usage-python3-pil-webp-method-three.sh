#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-method-three
# @title: Pillow WebP save method=3
# @description: Saves an RGB Pillow image to lossy WebP with method=3 and verifies the output reopens as WEBP at the source dimensions.
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
src = Image.new('RGB', (8, 6))
src.putdata([
    (i * 7 % 256, i * 11 % 256, i * 13 % 256) for i in range(8 * 6)
])
out = tmpdir / 'm3.webp'
src.save(out, 'WEBP', method=3, quality=70)
with Image.open(out) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    assert im.size == (8, 6), im.size
print('method3', out.stat().st_size)
PY
