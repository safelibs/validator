#!/usr/bin/env bash
# @testcase: usage-python3-pil-jpeg-subsampling-keep
# @title: Pillow JPEG subsampling keep
# @description: Saves a JPEG with subsampling=0 via Pillow and verifies the chroma layout via JpegImagePlugin.get_sampling.
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
from PIL.JpegImagePlugin import get_sampling
import sys

tmpdir = Path(sys.argv[1])
src = Image.new('RGB', (16, 16))
src.putdata([((x * 13) % 256, (y * 19) % 256, ((x + y) * 7) % 256) for y in range(16) for x in range(16)])

paths = {}
for label, sub in (('s0', 0), ('s2', 2)):
    p = tmpdir / f'{label}.jpg'
    src.save(p, 'JPEG', quality=90, subsampling=sub)
    paths[label] = p

with Image.open(paths['s0']) as im:
    im.load()
    sampling = get_sampling(im)
    # Pillow returns 0 for 4:4:4 (no chroma subsampling)
    assert sampling == 0, f"subsampling=0 expected get_sampling==0, got {sampling}"

with Image.open(paths['s2']) as im:
    im.load()
    sampling = get_sampling(im)
    # Pillow returns 2 for 4:2:0
    assert sampling == 2, f"subsampling=2 expected get_sampling==2, got {sampling}"

print('s0 ok, s2 ok')
PYCASE

file "$tmpdir/s0.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
