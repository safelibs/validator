#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-tiffinfo-bps-16bit-gray
# @title: Pillow TIFF tiffinfo BitsPerSample for 16-bit grayscale
# @description: Writes a 16-bit grayscale (I;16) TIFF with Pillow, runs tiffinfo, and verifies the Bits/Sample line reports 16 and the Photometric Interpretation is the min-is-black grayscale flavour. (tiffinfo only emits a Samples/Pixel line when SamplesPerPixel > 1, so we use Photometric Interpretation as the single-band sanity check instead.)
# @timeout: 180
# @tags: usage, image, python, cli, grayscale
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$tmpdir/i16.tiff"

python3 - <<'PY' "$img"
import sys
from PIL import Image

path = sys.argv[1]
size = (32, 20)
image = Image.new("I;16", size)
data = [((x * 257 + y * 1031) & 0xFFFF) for y in range(size[1]) for x in range(size[0])]
image.putdata(data)
image.save(path)

with Image.open(path) as reopened:
    reopened.load()
    bps_raw = reopened.tag_v2.get(258)
    bps = bps_raw[0] if hasattr(bps_raw, "__len__") else bps_raw
    spp = reopened.tag_v2.get(277)
    assert bps == 16, ("bits_per_sample", bps_raw)
    assert spp == 1 or spp is None, ("samples_per_pixel", spp)
    assert reopened.mode == "I;16", reopened.mode
    print("i16", bps, spp, reopened.size)
PY

validator_require_file "$img"

report="$tmpdir/info.txt"
tiffinfo "$img" >"$report"
validator_assert_contains "$report" "Bits/Sample: 16"
validator_assert_contains "$report" "Photometric Interpretation: min-is-black"
