#!/usr/bin/env bash
# @testcase: usage-python3-pil-multipage-tiff
# @title: Pillow multipage tiff
# @description: Uses Pillow to run TIFF multipage tiff behavior through libtiff.
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
a=Image.new('RGB',(2,2),'red'); b=Image.new('RGB',(2,2),'blue'); a.save(sys.argv[2], save_all=True, append_images=[b]); im=Image.open(sys.argv[2]); print('frames', getattr(im, 'n_frames', 1))
PY
