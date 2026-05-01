#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-i-mode-int32-roundtrip
# @title: Pillow TIFF I (int32) mode round-trip with SampleFormat=2 and BitsPerSample=32
# @description: Saves a Pillow "I" (32-bit signed integer) image to a temporary TIFF and verifies the reopened image preserves the mode, BitsPerSample tag (258) equals 32, SampleFormat tag (339) equals 2 (signed integer), pixel size is preserved, and the raw int32 putpixel value round-trips through getpixel.
# @timeout: 180
# @tags: usage, image, python, mode, sampleformat
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/i32.tiff"
import sys
from PIL import Image


def first(value):
    if isinstance(value, tuple):
        assert len(value) >= 1, value
        return value[0]
    return value


path = sys.argv[1]
size = (5, 4)
image = Image.new("I", size, 0)
# Embed a recognizable signed int32 that exceeds uint16 range so a misread
# would clamp/truncate visibly.
image.putpixel((0, 0), 1_000_000)
image.putpixel((4, 3), -250_000)
image.save(path)

with Image.open(path) as reopened:
    reopened.load()
    bps = first(reopened.tag_v2.get(258))
    sample_format = first(reopened.tag_v2.get(339))
    samples_per_pixel = first(reopened.tag_v2.get(277, 1))
    assert reopened.mode == "I", reopened.mode
    assert reopened.size == size, reopened.size
    assert bps == 32, ("BitsPerSample", reopened.tag_v2.get(258))
    assert sample_format == 2, ("SampleFormat", reopened.tag_v2.get(339))
    assert samples_per_pixel == 1, ("SamplesPerPixel", samples_per_pixel)
    assert reopened.getpixel((0, 0)) == 1_000_000, reopened.getpixel((0, 0))
    assert reopened.getpixel((4, 3)) == -250_000, reopened.getpixel((4, 3))
    print("i32", bps, sample_format, reopened.size)
PY
