#!/usr/bin/env bash
# @testcase: usage-python3-pil-r18-tiff-bits-per-sample-rgb-equals-8
# @title: Pillow RGB TIFF reports BitsPerSample tag 258 as three 8-bit values
# @description: Saves a small RGB TIFF, reopens it with Pillow, asserts tag_v2[258] (BitsPerSample) is an iterable yielding exactly three values each equal to 8, confirming libtiff records 8-bit-per-channel sample depth for the standard RGB photometric.
# @timeout: 60
# @tags: usage, tiff, python, bitspersample, r18
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/bps.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (4, 4), (10, 20, 30)).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    bps = im.tag_v2.get(258)
    vals = list(bps) if hasattr(bps, '__iter__') else [bps]
    assert len(vals) == 3, ('count', vals)
    for v in vals:
        assert int(v) == 8, ('bits', v)
print('ok bps=%s' % vals)
PY
