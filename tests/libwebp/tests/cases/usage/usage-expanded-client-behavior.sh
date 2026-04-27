#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageChops, ImageOps
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'input.webp'
output = tmpdir / 'out.webp'
base = Image.new('RGB', (4, 3))
base.putdata([
    (10, 20, 30), (40, 50, 60), (70, 80, 90), (100, 110, 120),
    (130, 30, 20), (20, 140, 40), (30, 50, 150), (200, 210, 40),
    (15, 200, 100), (220, 30, 180), (90, 160, 10), (250, 250, 250),
])
base.save(source, 'WEBP', lossless=True)

def round_trip(image):
    image.save(output, 'WEBP', lossless=True)
    with Image.open(output) as written:
        assert written.mode == image.mode
        assert written.size == image.size

def left_half_mask(size):
    mask = Image.new('L', size, 0)
    for x in range(size[0] // 2):
        for y in range(size[1]):
            mask.putpixel((x, y), 255)
    return mask

with Image.open(source) as opened:
    mirror = ImageOps.mirror(opened)
    first = opened.getpixel((0, 0))
    mirrored_first = mirror.getpixel((0, 0))

    if case_id == 'usage-python3-pil-transverse-generated-webp':
        out = opened.transpose(Image.Transpose.TRANSVERSE)
        assert out.size == (3, 4)
        assert out.getpixel((0, 0)) == opened.getpixel((3, 2))
        assert out.getpixel((2, 3)) == opened.getpixel((0, 0))
        round_trip(out)
        print(out.size)
    elif case_id == 'usage-python3-pil-blend-mirror-webp':
        out = Image.blend(opened, mirror, 0.5)
        expected = tuple((left + right) // 2 for left, right in zip(first, mirrored_first))
        assert out.getpixel((0, 0)) == expected
        round_trip(out)
        print(expected)
    elif case_id == 'usage-python3-pil-composite-halves-webp':
        out = Image.composite(opened, mirror, left_half_mask(opened.size))
        assert out.getpixel((0, 1)) == opened.getpixel((0, 1))
        assert out.getpixel((3, 1)) == opened.getpixel((0, 1))
        assert out.getpixel((3, 1)) != opened.getpixel((3, 1))
        round_trip(out)
        print(out.getpixel((3, 1)))
    elif case_id == 'usage-python3-pil-darker-mirror-webp':
        out = ImageChops.darker(opened, mirror)
        expected = tuple(min(left, right) for left, right in zip(first, mirrored_first))
        assert out.getpixel((0, 0)) == expected
        round_trip(out)
        print(expected)
    elif case_id == 'usage-python3-pil-lighter-mirror-webp':
        out = ImageChops.lighter(opened, mirror)
        expected = tuple(max(left, right) for left, right in zip(first, mirrored_first))
        assert out.getpixel((0, 0)) == expected
        round_trip(out)
        print(expected)
    elif case_id == 'usage-python3-pil-multiply-mirror-webp':
        out = ImageChops.multiply(opened, mirror)
        expected = tuple((left * right) // 255 for left, right in zip(first, mirrored_first))
        assert out.getpixel((0, 0)) == expected
        round_trip(out)
        print(expected)
    elif case_id == 'usage-python3-pil-add-mirror-webp':
        out = ImageChops.add(opened, mirror)
        expected = tuple(min(255, left + right) for left, right in zip(first, mirrored_first))
        assert out.getpixel((0, 0)) == expected
        round_trip(out)
        print(expected)
    elif case_id == 'usage-python3-pil-subtract-mirror-webp':
        out = ImageChops.subtract(mirror, opened)
        expected = tuple(max(0, right - left) for left, right in zip(first, mirrored_first))
        assert out.getpixel((0, 0)) == expected
        round_trip(out)
        print(expected)
    elif case_id == 'usage-python3-pil-screen-mirror-webp':
        out = ImageChops.screen(opened, mirror)
        expected = tuple(255 - ((255 - left) * (255 - right) // 255) for left, right in zip(first, mirrored_first))
        assert out.getpixel((0, 0)) == expected
        round_trip(out)
        print(expected)
    elif case_id == 'usage-python3-pil-invert-generated-webp':
        out = ImageOps.invert(opened)
        expected = tuple(255 - channel for channel in first)
        assert out.getpixel((0, 0)) == expected
        round_trip(out)
        print(expected)
    else:
        raise SystemExit(f'unknown libwebp expanded usage case: {case_id}')
PYCASE
