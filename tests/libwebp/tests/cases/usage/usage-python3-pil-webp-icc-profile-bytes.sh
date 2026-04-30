#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-icc-profile-bytes
# @title: Pillow WebP save with explicit icc_profile bytes
# @description: Saves a WebP through Pillow embedding a synthetic icc_profile byte string, then reopens the file and verifies the format and that info['icc_profile'] roundtrips byte-for-byte.
# @timeout: 180
# @tags: usage, webp, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-icc-profile-bytes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

icc = bytes(range(64)) * 4  # 256-byte synthetic profile blob
base = Image.new('RGB', (8, 6), (50, 100, 150))

out = tmpdir / 'icc.webp'
base.save(out, 'WEBP', quality=85, icc_profile=icc, lossless=True)

assert out.is_file()
header = out.read_bytes()[:12]
assert header[:4] == b'RIFF', header[:4]
assert header[8:12] == b'WEBP', header[8:12]

with Image.open(out) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    assert im.size == (8, 6), im.size
    got = im.info.get('icc_profile')

assert got is not None, 'icc_profile not preserved'
assert isinstance(got, (bytes, bytearray)), type(got)
assert bytes(got) == icc, (len(got), len(icc))
print('icc_profile bytes', len(got))
PYCASE
