#!/usr/bin/env bash
# @testcase: usage-python3-pil-jpeg-info-progressive
# @title: Pillow JPEG progressive flag
# @description: Saves progressive and baseline JPEGs via Pillow and checks info['progressive'] differs.
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
src = Image.new('RGB', (16, 12))
src.putdata([((x * 17) % 256, (y * 23) % 256, ((x + y) * 11) % 256) for y in range(12) for x in range(16)])

baseline = tmpdir / 'baseline.jpg'
progressive = tmpdir / 'progressive.jpg'
src.save(baseline, 'JPEG', quality=85, progressive=False)
src.save(progressive, 'JPEG', quality=85, progressive=True)

with Image.open(baseline) as b:
    b.load()
    assert b.format == 'JPEG'
    assert not b.info.get('progressive', False), f"baseline unexpectedly progressive: {b.info!r}"

with Image.open(progressive) as p:
    p.load()
    assert p.format == 'JPEG'
    assert p.info.get('progressive'), f"progressive flag missing: {p.info!r}"

print('baseline', baseline.stat().st_size, 'progressive', progressive.stat().st_size)
PYCASE

file "$tmpdir/progressive.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
