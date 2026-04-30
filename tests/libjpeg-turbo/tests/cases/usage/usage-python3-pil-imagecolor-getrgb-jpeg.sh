#!/usr/bin/env bash
# @testcase: usage-python3-pil-imagecolor-getrgb-jpeg
# @title: Pillow ImageColor.getrgb parsing for JPEG fill
# @description: Uses ImageColor.getrgb to parse common color string forms (named, hex short, hex long, rgb function), creates a JPEG filled with each parsed color, and verifies a roundtrip getpixel matches the parsed RGB tuple.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-imagecolor-getrgb-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageColor
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

specs = [
    ('red', (255, 0, 0)),
    ('#0f0', (0, 255, 0)),
    ('#0000ff', (0, 0, 255)),
    ('rgb(20, 200, 90)', (20, 200, 90)),
]

for spec, expected in specs:
    parsed = ImageColor.getrgb(spec)
    assert parsed == expected, (spec, parsed, expected)

    out = tmpdir / f'fill-{specs.index((spec, expected))}.jpg'
    Image.new('RGB', (16, 16), parsed).save(out, 'JPEG', quality=100, subsampling=0)

    with Image.open(out) as im:
        assert im.format == 'JPEG'
        assert im.mode == 'RGB'
        assert im.size == (16, 16)
        r, g, b = im.getpixel((8, 8))
        # JPEG quantization at q=100 stays close to the original color.
        assert abs(r - expected[0]) < 8, (spec, (r, g, b), expected)
        assert abs(g - expected[1]) < 8, (spec, (r, g, b), expected)
        assert abs(b - expected[2]) < 8, (spec, (r, g, b), expected)
    assert out.read_bytes()[:3] == b'\xff\xd8\xff'
    print('getrgb', spec, parsed)

PYCASE

ls "$tmpdir"/fill-*.jpg | wc -l | tee "$tmpdir/count.out"
[[ "$(cat "$tmpdir/count.out")" == "4" ]] || { echo "expected 4 files" >&2; exit 1; }
