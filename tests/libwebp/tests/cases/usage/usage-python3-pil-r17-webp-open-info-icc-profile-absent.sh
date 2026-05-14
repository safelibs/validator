#!/usr/bin/env bash
# @testcase: usage-python3-pil-r17-webp-open-info-icc-profile-absent
# @title: Pillow WEBP info has no icc_profile key for an image saved without ICC
# @description: Saves a small RGB image as WEBP without supplying ICC, re-opens the image, and asserts the Pillow info dict either lacks the 'icc_profile' key or holds an empty/falsy value — exercising libwebp's optional ICC chunk absence path.
# @timeout: 60
# @tags: usage, python3-pil, webp, icc
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/out.webp" <<'PY'
import sys
from PIL import Image

img = Image.new('RGB', (16, 16), (40, 80, 120))
img.save(sys.argv[1], 'WEBP', quality=80)

with Image.open(sys.argv[1]) as out:
    out.load()
    icc = out.info.get('icc_profile')
    assert not icc, ('expected no ICC profile', icc)
PY
