#!/usr/bin/env bash
# @testcase: usage-python3-pil-imageenhance-brightness-jpeg
# @title: Pillow ImageEnhance.Brightness JPEG roundtrip
# @description: Applies ImageEnhance.Brightness factor 1.0 (identity) and 0.0 (black) to a JPEG and verifies behavior plus a JPEG roundtrip.
# @timeout: 180
# @tags: usage, jpeg, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-imageenhance-brightness-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image, ImageEnhance, ImageStat
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
source = tmpdir / 'in.jpg'
identity = tmpdir / 'identity.jpg'
darkened = tmpdir / 'darkened.jpg'

Image.new('RGB', (8, 6), (180, 90, 60)).save(source, 'JPEG', quality=95, subsampling=0)

with Image.open(source) as im:
    assert im.format == 'JPEG'
    assert im.mode == 'RGB'
    base_mean = ImageStat.Stat(im).mean
    enhancer = ImageEnhance.Brightness(im)
    enhancer.enhance(1.0).save(identity, 'JPEG', quality=95, subsampling=0)
    enhancer.enhance(0.0).save(darkened, 'JPEG', quality=95, subsampling=0)

with Image.open(identity) as im:
    assert im.format == 'JPEG'
    assert im.size == (8, 6)
    identity_mean = ImageStat.Stat(im).mean
    for o, e in zip(identity_mean, base_mean):
        assert abs(o - e) < 5.0, (o, e)

with Image.open(darkened) as im:
    assert im.format == 'JPEG'
    assert im.size == (8, 6)
    dark_mean = ImageStat.Stat(im).mean
    for v in dark_mean:
        assert v < 5.0, dark_mean

print('identity_mean', identity_mean, 'dark_mean', dark_mean)
PYCASE

file "$tmpdir/identity.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'
