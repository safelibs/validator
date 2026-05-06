#!/usr/bin/env bash
# @testcase: usage-python3-pil-r11-webp-icc-profile-roundtrip
# @title: Pillow WEBP icc_profile= survives lossless save/load byte-for-byte
# @description: Builds an sRGB ICC profile via PIL.ImageCms, saves a lossless WebP with that icc_profile=, and re-opens to confirm im.info["icc_profile"] equals the source bytes exactly.
# @timeout: 180
# @tags: usage, python3-pil, webp, icc
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/icc.webp"
import sys
from PIL import Image, ImageCms

prof = ImageCms.ImageCmsProfile(ImageCms.createProfile('sRGB')).tobytes()
assert len(prof) > 0
src = Image.new('RGB', (8, 8), (10, 220, 100))
src.save(sys.argv[1], 'WEBP', icc_profile=prof, lossless=True)

with Image.open(sys.argv[1]) as im:
    im.load()
    out_prof = im.info.get('icc_profile')
    assert out_prof == prof, (len(prof), len(out_prof or b''))
PY
