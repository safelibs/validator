#!/usr/bin/env bash
# @testcase: usage-python3-pil-jpeg-quality-size-delta
# @title: Pillow JPEG quality 95 vs 40 size delta
# @description: Encodes the same noisy 256x256 image at quality=95 and quality=40 with Pillow and asserts the high-quality output is materially larger, exercising libjpeg-turbo's quantization scaling.
# @timeout: 180
# @tags: usage, jpeg, python, encoder
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
W, H = 256, 256
# Noisy data so quantization at low Q has plenty to throw away.
src = Image.new('RGB', (W, H))
src.putdata([(((x * 7) ^ (y * 5)) & 255, (x + y * 3) & 255, (x * y) & 255)
             for y in range(H) for x in range(W)])

hi = tmpdir / 'q95.jpg'
lo = tmpdir / 'q40.jpg'
src.save(hi, 'JPEG', quality=95)
src.save(lo, 'JPEG', quality=40)

hi_bytes = hi.stat().st_size
lo_bytes = lo.stat().st_size
print('q95', hi_bytes, 'q40', lo_bytes)

# Q=95 must be strictly larger than Q=40 on this noisy fixture, with plenty
# of headroom — libjpeg-turbo's quality scaling collapses if the quant tables
# are not honored.
assert hi_bytes > lo_bytes * 2, f'q95 not >2x q40: q95={hi_bytes} q40={lo_bytes}'

# Both are valid JPEGs.
for p in (hi, lo):
    data = p.read_bytes()
    assert data[:2] == b'\xff\xd8' and data[-2:] == b'\xff\xd9', f'invalid JPEG: {p.name}'
PYCASE
