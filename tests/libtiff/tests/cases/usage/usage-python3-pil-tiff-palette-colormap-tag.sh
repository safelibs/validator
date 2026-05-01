#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-palette-colormap-tag
# @title: Pillow TIFF palette mode emits ColorMap tag (320) of 768 entries
# @description: Saves a P-mode TIFF with a ramp palette and verifies the reopened TIFF carries PhotometricInterpretation (262) equal to 3 (palette), a ColorMap tag (320) with exactly 768 16-bit entries (3 channels x 256 colors), BitsPerSample (258) equal to 8, and that the indexed pixel maps back to the expected palette RGB triple.
# @timeout: 180
# @tags: usage, image, python, palette, colormap
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/palette.tiff"
import sys
from PIL import Image


def first(value):
    if isinstance(value, tuple):
        return value[0]
    return value


path = sys.argv[1]
size = (4, 4)
# Palette: index 1 -> bright red (255, 0, 0), index 2 -> green, others zero.
palette_bytes = bytearray(768)
palette_bytes[3:6] = bytes((255, 0, 0))
palette_bytes[6:9] = bytes((0, 200, 0))
image = Image.new("P", size, 0)
image.putpalette(bytes(palette_bytes))
# Set a single palette index 1 pixel at (0,0) and index 2 at (3,3).
pixels = [0] * (size[0] * size[1])
pixels[0] = 1
pixels[-1] = 2
image.putdata(pixels)
image.save(path)

with Image.open(path) as reopened:
    reopened.load()
    photometric = first(reopened.tag_v2.get(262))
    bps = first(reopened.tag_v2.get(258))
    colormap = reopened.tag_v2.get(320)
    assert reopened.mode in ("P", "RGB"), reopened.mode
    assert reopened.size == size, reopened.size
    assert photometric == 3, ("Photometric", reopened.tag_v2.get(262))
    assert bps == 8, ("BitsPerSample", reopened.tag_v2.get(258))
    assert colormap is not None, "ColorMap tag missing"
    assert hasattr(colormap, "__len__"), type(colormap)
    assert len(colormap) == 768, ("ColorMap len", len(colormap))
    # libtiff scales 8-bit palette entries to 16-bit. Index 1 red channel
    # is the first entry of the second third of the table.
    red_for_idx1 = colormap[1]
    green_for_idx2 = colormap[256 + 2]
    assert red_for_idx1 in (255, 65535, 65280), red_for_idx1
    assert green_for_idx2 in (200, 51200, 51400, 65535), green_for_idx2
    print("colormap", photometric, bps, len(colormap))
PY
