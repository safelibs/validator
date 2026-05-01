#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-rgba-extrasamples-tag
# @title: Pillow TIFF RGBA ExtraSamples tag (338) marks the alpha channel
# @description: Saves a Pillow RGBA TIFF and verifies that on reload SamplesPerPixel (277) equals 4, ExtraSamples (338) is present and contains exactly one entry equal to 2 (unassociated alpha), PhotometricInterpretation (262) equals 2 (RGB), and the constant alpha pixel round-trips byte-for-byte.
# @timeout: 180
# @tags: usage, image, python, alpha, rgba
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/rgba.tiff"
import sys
from PIL import Image


def as_tuple(value):
    if value is None:
        return ()
    if isinstance(value, tuple):
        return value
    if hasattr(value, "__len__") and not isinstance(value, (bytes, str)):
        return tuple(value)
    return (value,)


path = sys.argv[1]
size = (6, 5)
constant = (12, 200, 64, 137)
image = Image.new("RGBA", size, constant)
image.save(path)

with Image.open(path) as reopened:
    reopened.load()
    samples = reopened.tag_v2.get(277)
    extras = as_tuple(reopened.tag_v2.get(338))
    photometric = reopened.tag_v2.get(262)
    samples_val = samples[0] if isinstance(samples, tuple) else samples
    photometric_val = photometric[0] if isinstance(photometric, tuple) else photometric
    assert reopened.mode == "RGBA", reopened.mode
    assert reopened.size == size, reopened.size
    assert samples_val == 4, ("SamplesPerPixel", samples)
    assert photometric_val == 2, ("Photometric", photometric)
    assert len(extras) == 1, ("ExtraSamples len", extras)
    assert extras[0] == 2, ("ExtraSamples value", extras)
    assert reopened.getpixel((0, 0)) == constant, reopened.getpixel((0, 0))
    assert reopened.getpixel((size[0] - 1, size[1] - 1)) == constant
    print("rgba-extrasamples", samples_val, extras, photometric_val)
PY
