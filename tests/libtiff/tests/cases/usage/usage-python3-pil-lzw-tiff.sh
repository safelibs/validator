#!/usr/bin/env bash
# @testcase: usage-python3-pil-lzw-tiff
# @title: Pillow lzw tiff
# @description: Uses Pillow to run TIFF lzw tiff behavior through libtiff.
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
im=Image.new('RGB',(4,4),'green'); im.save(sys.argv[2], compression='tiff_lzw'); print(Image.open(sys.argv[2]).size)
PY
