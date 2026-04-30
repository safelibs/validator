#!/usr/bin/env bash
# @testcase: usage-python3-pil-jpeg-comment-roundtrip
# @title: Pillow JPEG comment roundtrip
# @description: Embeds a JPEG COM marker via Pillow save and verifies info['comment'] on reopen.
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
src = Image.new('RGB', (10, 10))
src.putdata([((x * 7) % 256, (y * 11) % 256, ((x ^ y) * 13) % 256) for y in range(10) for x in range(10)])
out = tmpdir / 'commented.jpg'
expected = b'safelibs-validator-comment'
src.save(out, 'JPEG', quality=90, comment=expected)

with Image.open(out) as im:
    im.load()
    assert im.format == 'JPEG'
    assert im.size == (10, 10)
    actual = im.info.get('comment')
    assert actual == expected, f"comment mismatch: {actual!r}"
print('comment', actual)
PYCASE

file "$tmpdir/commented.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
