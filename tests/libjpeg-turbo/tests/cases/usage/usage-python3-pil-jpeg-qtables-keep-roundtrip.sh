#!/usr/bin/env bash
# @testcase: usage-python3-pil-jpeg-qtables-keep-roundtrip
# @title: Pillow JPEG qtables=keep roundtrip
# @description: Reencodes a JPEG with qtables=keep via Pillow and verifies the quantization tables match the source byte-for-byte.
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
src = Image.new('RGB', (16, 16))
src.putdata([((x * 13) & 255, (y * 19) & 255, ((x ^ y) * 7) & 255)
             for y in range(16) for x in range(16)])

orig = tmpdir / 'orig.jpg'
src.save(orig, 'JPEG', quality=72, subsampling=2)

with Image.open(orig) as im:
    im.load()
    src_q = im.quantization
    out = tmpdir / 'keep.jpg'
    im.save(out, 'JPEG', qtables='keep')

with Image.open(out) as im:
    im.load()
    keep_q = im.quantization

assert src_q.keys() == keep_q.keys(), f'table set differs {src_q.keys()} vs {keep_q.keys()}'
for k in src_q:
    assert list(src_q[k]) == list(keep_q[k]), f'table {k} mutated by qtables=keep'
print('qtables=keep preserved', list(src_q.keys()))
PYCASE
