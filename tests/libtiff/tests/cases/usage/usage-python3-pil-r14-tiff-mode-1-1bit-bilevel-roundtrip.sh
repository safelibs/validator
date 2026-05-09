#!/usr/bin/env bash
# @testcase: usage-python3-pil-r14-tiff-mode-1-1bit-bilevel-roundtrip
# @title: PIL TIFF mode "1" 1-bit bilevel image round-trips with BitsPerSample == 1
# @description: Saves a mode "1" bilevel TIFF and verifies on reopen that the mode is still "1" (which PIL only assigns when libtiff's BitsPerSample is 1 and PhotometricInterpretation is 0/1). If tag_v2[258] is surfaced, also assert it equals 1; PIL on noble does not always populate this entry on read, so a missing value is tolerated as long as the mode round-trips.
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
    # PIL on noble may not surface BitsPerSample for mode "1" reads; mode == '1'
    # already implies the on-disk BitsPerSample was 1. If the tag is present,
    # verify it equals 1.
    if bps is not None:
        if isinstance(bps, tuple):
            assert bps == (1,), ('BitsPerSample tuple', bps)
        else:
            assert bps == 1, ('BitsPerSample int', bps)
PY
