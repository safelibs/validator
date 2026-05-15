#!/usr/bin/env bash
# @testcase: usage-python3-pil-r19-webp-getbands-rgb-three-bands
# @title: Pillow getbands() on a reopened RGB WEBP returns the R,G,B tuple
# @description: Saves an RGB image as WEBP via Pillow, reopens it through Image.open, and asserts img.getbands() returns the tuple ('R', 'G', 'B') exactly — pinning the libwebp-driven RGB band exposure.
# @timeout: 60
# @tags: usage, python3-pil, webp, getbands, r19
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/out.webp" <<'PY'
import sys
from PIL import Image

img = Image.new('RGB', (24, 18), (30, 90, 200))
img.save(sys.argv[1], 'WEBP', quality=80)

with Image.open(sys.argv[1]) as out:
    out.load()
    bands = out.getbands()
    assert bands == ('R', 'G', 'B'), bands
PY
