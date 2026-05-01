#!/usr/bin/env bash
# @testcase: usage-python3-pil-jpeg-icc-profile-roundtrip
# @title: Pillow JPEG ICC profile roundtrip
# @description: Saves a JPEG with a synthetic icc_profile bytes payload and verifies Pillow re-exposes the same bytes via info on reopen.
# @timeout: 180
# @tags: usage, jpeg, python, color
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
src = Image.new('RGB', (12, 9))
src.putdata([((x * 17) % 256, (y * 23) % 256, ((x + y) * 11) % 256) for y in range(9) for x in range(12)])

# Build a fake but plausible 256-byte ICC payload. JPEG's APP2 marker carries
# the ICC blob verbatim; libjpeg-turbo + Pillow should preserve it byte-for-byte.
icc = bytes((i * 3 + 7) % 256 for i in range(256))

out = tmpdir / 'icc.jpg'
src.save(out, 'JPEG', quality=88, icc_profile=icc)

with Image.open(out) as im:
    im.load()
    got = im.info.get('icc_profile')
assert got == icc, f"ICC profile mismatch: len={len(got) if got else None}"
print('icc roundtrip ok', len(got))
PYCASE

file "$tmpdir/icc.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
