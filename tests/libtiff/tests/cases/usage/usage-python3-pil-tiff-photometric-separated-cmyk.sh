#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-photometric-separated-cmyk
# @title: Pillow TIFF photometric separated CMYK
# @description: Writes a CMYK TIFF and verifies PhotometricInterpretation equals 5 (separated) and SamplesPerPixel equals 4.
# @timeout: 180
# @tags: usage, image, python, photometric, cmyk
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/separated.tiff"
from PIL import Image
import sys

path = sys.argv[1]
size = (5, 4)
image = Image.new("CMYK", size, (10, 60, 120, 200))
image.save(path)

with Image.open(path) as reopened:
    reopened.load()
    photometric = reopened.tag_v2.get(262)
    samples = reopened.tag_v2.get(277)
    assert photometric == 5, photometric
    assert samples == 4, samples
    assert reopened.mode == "CMYK", reopened.mode
    assert reopened.size == size, reopened.size
    print("separated", photometric, samples, reopened.size)
PY
