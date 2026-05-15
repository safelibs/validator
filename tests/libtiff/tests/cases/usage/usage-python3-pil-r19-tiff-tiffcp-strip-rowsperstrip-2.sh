#!/usr/bin/env bash
# @testcase: usage-python3-pil-r19-tiff-tiffcp-strip-rowsperstrip-2
# @title: libtiff tiffcp -r 2 produces an output TIFF whose RowsPerStrip tag equals 2
# @description: Generates a 16x16 RGB source TIFF via Pillow, invokes "tiffcp -r 2" to repackage it with two rows per strip, opens the output with Pillow, asserts tag_v2[278] (RowsPerStrip) equals 2, and asserts tag_v2[279] (StripByteCounts) is a tuple of 8 entries (16 rows / 2 rows per strip), confirming libtiff's strip-layout control via the tiffcp CLI.
# @timeout: 60
# @tags: usage, tiff, python, tiffcp, rowsperstrip, cli, r19
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/src.tif"
dst="$tmpdir/dst.tif"

python3 - "$src" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (16, 16), (40, 80, 120)).save(sys.argv[1], 'TIFF')
PY

tiffcp -r 2 "$src" "$dst" >/dev/null

python3 - "$dst" <<'PY'
import sys
from PIL import Image
with Image.open(sys.argv[1]) as im:
    im.load()
    rps = im.tag_v2.get(278)
    sbc = im.tag_v2.get(279)
    if not isinstance(sbc, tuple):
        sbc = (sbc,)
    assert int(rps) == 2, ('rps', rps)
    assert len(sbc) == 8, ('strips', sbc)
print('ok rps=%d strips=%d' % (int(rps), len(sbc)))
PY
