#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    tiff="$VALIDATOR_SOURCE_ROOT/test/images/rgb-3c-8b.tiff"
validator_require_file "$tiff"
python3 - <<'PY' "$tiff" "$tmpdir/out.tiff"
from PIL import Image
im=Image.open('/validator/tests/libtiff/tests/tagged-port/original/test/images/test_float64_predictor2_le_lzw.tif'); im.load(); print(im.mode, im.size)
PY