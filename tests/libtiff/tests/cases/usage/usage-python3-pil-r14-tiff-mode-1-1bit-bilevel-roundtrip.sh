#!/usr/bin/env bash
# @testcase: usage-python3-pil-r14-tiff-mode-1-1bit-bilevel-roundtrip
# @title: PIL TIFF mode "1" 1-bit bilevel image round-trips with BitsPerSample == 1
# @description: Saves a mode "1" bilevel TIFF and verifies on reopen that the mode is still "1" and tag_v2[258] (BitsPerSample) equals 1, asserting libtiff stores 1-bit bilevel imagery with the canonical BitsPerSample value rather than promoting to 8.
# @timeout: 60
# @tags: usage, tiff, python, mode-1, bilevel
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/bilevel.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('1', (16, 16), 1).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.mode == '1', ('mode', im.mode)
    bps = im.tag_v2.get(258)
    # BitsPerSample may surface as int or 1-tuple
    if isinstance(bps, tuple):
        assert bps == (1,), ('BitsPerSample tuple', bps)
    else:
        assert bps == 1, ('BitsPerSample int', bps)
PY
