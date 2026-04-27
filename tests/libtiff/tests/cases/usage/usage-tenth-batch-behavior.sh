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
source = tmpdir / 'input.tiff'
output = tmpdir / 'out.tiff'
base = Image.new('RGB', (4, 3))
base.putdata([
    (10, 20, 30), (40, 50, 60), (70, 80, 90), (100, 110, 120),
    (130, 30, 20), (20, 140, 40), (30, 50, 150), (200, 210, 40),
    (15, 200, 100), (220, 30, 180), (90, 160, 10), (250, 250, 250),
])
base.save(source, 'TIFF')

def round_trip(image):
    image.save(output, 'TIFF')
    with Image.open(output) as written:
        assert written.mode == image.mode
        assert written.size == image.size

with Image.open(source) as opened:
    mirror = ImageOps.mirror(opened)
    first = opened.getpixel((0, 0))
    mirrored_first = mirror.getpixel((0, 0))

    if case_id == 'usage-python3-pil-difference-mirror-tiff':
        out = ImageChops.difference(opened, mirror)
        expected = tuple(abs(left - right) for left, right in zip(first, mirrored_first))
        assert out.getpixel((0, 0)) == expected
        round_trip(out)
        print(expected)
    elif case_id == 'usage-python3-pil-add-modulo-mirror-tiff':
        out = ImageChops.add_modulo(opened, mirror)
        expected = tuple((left + right) % 256 for left, right in zip(first, mirrored_first))
        assert out.getpixel((0, 0)) == expected
        round_trip(out)
        print(expected)
    elif case_id == 'usage-python3-pil-subtract-modulo-mirror-tiff':
        out = ImageChops.subtract_modulo(opened, mirror)
        expected = tuple((left - right) % 256 for left, right in zip(first, mirrored_first))
        assert out.getpixel((0, 0)) == expected
        round_trip(out)
        print(expected)
    elif case_id == 'usage-python3-pil-duplicate-darker-tiff':
        out = ImageChops.darker(opened, opened.copy())
        for x in range(opened.size[0]):
            for y in range(opened.size[1]):
                assert out.getpixel((x, y)) == opened.getpixel((x, y))
        round_trip(out)
        print(first)
    elif case_id == 'usage-python3-pil-invert-mirror-mirror-tiff':
        inverted = ImageOps.invert(mirror)
        out = ImageChops.lighter(opened, inverted)
        inv_first = tuple(255 - channel for channel in mirrored_first)
        expected = tuple(max(left, right) for left, right in zip(first, inv_first))
        assert out.getpixel((0, 0)) == expected
        round_trip(out)
        print(expected)
    elif case_id == 'usage-python3-pil-blend-zero-mirror-tiff':
        out = Image.blend(opened, mirror, 0.0)
        for x in range(opened.size[0]):
            for y in range(opened.size[1]):
                assert out.getpixel((x, y)) == opened.getpixel((x, y))
        round_trip(out)
        print(first)
    elif case_id == 'usage-python3-pil-blend-one-mirror-tiff':
        out = Image.blend(opened, mirror, 1.0)
        for x in range(opened.size[0]):
            for y in range(opened.size[1]):
                assert out.getpixel((x, y)) == mirror.getpixel((x, y))
        round_trip(out)
        print(mirrored_first)
    elif case_id == 'usage-python3-pil-grayscale-add-tiff':
        gray = opened.convert('L')
        gray_mirror = ImageOps.mirror(gray)
        out = ImageChops.add(gray, gray_mirror)
        first_l = gray.getpixel((0, 0))
        mirror_l = gray_mirror.getpixel((0, 0))
        assert out.getpixel((0, 0)) == min(255, first_l + mirror_l)
        out.save(output, 'TIFF')
        with Image.open(output) as written:
            assert written.size == out.size
            assert written.mode == 'L'
        print(out.getpixel((0, 0)))
    elif case_id == 'usage-python3-pil-mirror-twice-identity-tiff':
        out = ImageOps.mirror(mirror)
        for x in range(opened.size[0]):
            for y in range(opened.size[1]):
                assert out.getpixel((x, y)) == opened.getpixel((x, y))
        round_trip(out)
        print('identity')
    elif case_id == 'usage-python3-pil-flip-twice-identity-tiff':
        flipped = ImageOps.flip(opened)
        out = ImageOps.flip(flipped)
        for x in range(opened.size[0]):
            for y in range(opened.size[1]):
                assert out.getpixel((x, y)) == opened.getpixel((x, y))
        round_trip(out)
        print('identity')
    else:
        raise SystemExit(f'unknown libtiff tenth-batch usage case: {case_id}')
PYCASE
