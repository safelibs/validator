#!/usr/bin/env bash
# @testcase: usage-python3-pil-frombytes-jpeg
# @title: Pillow Image.frombytes round-trips JPEG
# @description: Decodes a JPEG with Pillow into raw RGB bytes via Image.tobytes, reconstructs the image with Image.frombytes, saves the result back as JPEG and verifies the round-tripped image preserves mode and dimensions.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-frombytes-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'in.jpg'
output = tmpdir / 'out.jpg'

base = Image.new('RGB', (8, 6))
base.putdata([(x * 30 % 256, y * 40 % 256, (x + y) * 20 % 256) for y in range(6) for x in range(8)])
base.save(source, 'JPEG', quality=95, subsampling=0)

with Image.open(source) as im:
    im.load()
    assert im.format == 'JPEG'
    assert im.mode == 'RGB'
    raw = im.tobytes()
    # Each RGB pixel is 3 bytes; 8x6 = 48 pixels => 144 bytes.
    assert len(raw) == 8 * 6 * 3, len(raw)
    rebuilt = Image.frombytes('RGB', im.size, raw)
    assert rebuilt.mode == 'RGB'
    assert rebuilt.size == (8, 6)
    # The reconstructed bytes must match the original decoded image exactly.
    assert rebuilt.tobytes() == raw
    rebuilt.save(output, 'JPEG', quality=95, subsampling=0)

with Image.open(output) as im:
    im.load()
    assert im.format == 'JPEG'
    assert im.mode == 'RGB'
    assert im.size == (8, 6)
    print('frombytes', im.mode, im.size)
PYCASE

file "$tmpdir/out.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
