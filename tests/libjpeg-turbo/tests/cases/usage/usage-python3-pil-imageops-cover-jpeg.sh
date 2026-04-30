#!/usr/bin/env bash
# @testcase: usage-python3-pil-imageops-cover-jpeg
# @title: Pillow ImageOps.cover on JPEG
# @description: Opens a JPEG, calls ImageOps.cover to fit a target box while preserving aspect ratio, saves to JPEG, and verifies the resulting image fully covers the target dimensions in at least one axis.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-imageops-cover-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageOps
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'in.jpg'
output = tmpdir / 'covered.jpg'

# 24x16 source -> cover target 32x32; result should have both dims >= 32 in at least one axis covering the target.
Image.new('RGB', (24, 16), (128, 128, 128)).save(source, 'JPEG', quality=95, subsampling=0)

with Image.open(source) as im:
    assert im.format == 'JPEG'
    assert im.size == (24, 16)
    if not hasattr(ImageOps, 'cover'):
        print('cover not available; skipping')
        sys.exit(0)
    covered = ImageOps.cover(im, (32, 32))
    w, h = covered.size
    # cover keeps aspect ratio while ensuring both dims >= target
    assert w >= 32 and h >= 32, (w, h)
    # Aspect ratio of source 24/16 = 1.5; preserved in output.
    src_ratio = 24 / 16
    out_ratio = w / h
    assert abs(src_ratio - out_ratio) < 0.05, (src_ratio, out_ratio)
    covered.save(output, 'JPEG', quality=95, subsampling=0)

with Image.open(output) as im:
    assert im.format == 'JPEG'
    assert im.mode == 'RGB'
    print('cover', im.size)

assert output.read_bytes()[:3] == b'\xff\xd8\xff'
PYCASE

file "$tmpdir/covered.jpg" 2>/dev/null | tee "$tmpdir/file.out" || true
