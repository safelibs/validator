#!/usr/bin/env bash
# @testcase: usage-python3-pil-r20-tiff-filesize-positive-and-nonzero
# @title: Pillow-written TIFF file size exceeds the raw pixel byte count
# @description: Saves a 16x16 mode-L TIFF via Pillow and asserts os.path.getsize of the resulting file is strictly greater than 16*16 (the raw pixel byte count) and less than 16384 (an extremely generous upper bound), confirming libtiff encodes recognisable container overhead (header + IFD + tags) around the strip payload.
# @timeout: 60
# @tags: usage, tiff, python, filesize, overhead, r20
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/sz.tif"

python3 - "$path" <<'PY'
import os, sys
from PIL import Image

Image.new('L', (16, 16), 200).save(sys.argv[1], 'TIFF')
sz = os.path.getsize(sys.argv[1])
assert sz > 16 * 16, ('too small', sz)
assert sz < 16384, ('too large', sz)
print('ok size=%d' % sz)
PY
