#!/usr/bin/env bash
# @testcase: usage-python3-pil-r11-tiff-rgba-extra-samples-alpha
# @title: PIL RGBA TIFF tags ExtraSamples=2 (unassociated alpha) and Samples/Pixel=4
# @description: Saves a Pillow RGBA TIFF and verifies tag_v2[277] SamplesPerPixel == 4 and tag_v2[338] ExtraSamples == (2,) (UNASSALPHA), confirming the alpha channel is recorded as unassociated alpha rather than premultiplied.
# @timeout: 60
# @tags: usage, tiff, python, alpha, rgba
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/rgba.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGBA', (40, 30), (255, 0, 0, 128)).save(sys.argv[1], 'TIFF')

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.tag_v2.get(277) == 4, ('SamplesPerPixel', im.tag_v2.get(277))
    extra = im.tag_v2.get(338)
    if isinstance(extra, int):
        extra = (extra,)
    assert tuple(extra) == (2,), ('ExtraSamples', extra)
PY

tiffinfo "$path" >"$tmpdir/info.out"
grep -E 'Extra Samples: 1<unassoc-alpha>' "$tmpdir/info.out" >/dev/null
grep -E 'Samples/Pixel: 4' "$tmpdir/info.out" >/dev/null
