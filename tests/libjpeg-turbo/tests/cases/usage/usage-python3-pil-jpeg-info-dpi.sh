#!/usr/bin/env bash
# @testcase: usage-python3-pil-jpeg-info-dpi
# @title: Pillow JPEG info dpi
# @description: Saves a JPEG with explicit dpi via Pillow and verifies info['dpi'] reads back.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

tmpdir = Path(sys.argv[1])
src = Image.new('RGB', (12, 8))
src.putdata([(x * 20 % 256, y * 30 % 256, (x * y) % 256) for y in range(8) for x in range(12)])
out = tmpdir / 'dpi.jpg'
src.save(out, 'JPEG', quality=90, dpi=(144, 144))

assert out.exists()
with Image.open(out) as im:
    im.load()
    assert im.format == 'JPEG'
    assert im.size == (12, 8)
    dpi = im.info.get('dpi')
    assert dpi is not None, f"missing dpi in info: {im.info!r}"
    assert int(round(dpi[0])) == 144 and int(round(dpi[1])) == 144, dpi
print('dpi', dpi, 'size', im.size)
PYCASE

file "$tmpdir/dpi.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
