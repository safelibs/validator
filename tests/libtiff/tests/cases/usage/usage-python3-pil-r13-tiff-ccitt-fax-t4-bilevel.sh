#!/usr/bin/env bash
# @testcase: usage-python3-pil-r13-tiff-ccitt-fax-t4-bilevel
# @title: PIL bilevel TIFF saved with group3 reports CCITT Group 3 in tiffinfo
# @description: Saves a Pillow mode='1' bilevel image with compression='group3' and verifies tiffinfo reports "Compression Scheme: CCITT Group 3" on the resulting file, asserting the libtiff Group 3 (T.4) fax codec round-trips through Pillow.
# @timeout: 60
# @tags: usage, tiff, python, compression, fax, group3
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/g3.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('1', (32, 24), 0).save(sys.argv[1], 'TIFF', compression='group3')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.mode == '1', ('mode', im.mode)
PY

tiffinfo "$path" >"$tmpdir/info.out"
grep -E 'Compression Scheme: CCITT Group 3' "$tmpdir/info.out" >/dev/null
