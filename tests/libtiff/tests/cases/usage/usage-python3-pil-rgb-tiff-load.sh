#!/usr/bin/env bash
# @testcase: usage-python3-pil-rgb-tiff-load
# @title: Pillow RGB tiff load
# @description: Opens an RGB TIFF fixture with Pillow to exercise libtiff-backed image decoding.
# @timeout: 180
# @tags: usage, image, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    tiff="$VALIDATOR_SAMPLE_ROOT/test/images/rgb-3c-8b.tiff"
validator_require_file "$tiff"
python3 - <<'PY' "$tiff" "$tmpdir/out.tiff"
from PIL import Image
import sys
im=Image.open(sys.argv[1]); im.load(); print(im.mode, im.size)
PY
