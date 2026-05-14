#!/usr/bin/env bash
# @testcase: usage-python3-pil-r18-tiff-info-dict-has-compression-key
# @title: Pillow TIFF im.info dict carries a compression key reflecting save compression
# @description: Saves an RGB TIFF with compression="tiff_lzw", reopens it with Pillow, asserts im.info is a dict, asserts it contains a "compression" key, and asserts the recorded value equals "tiff_lzw", confirming libtiff-backed compression metadata is exposed through Pillow's per-image info dictionary.
# @timeout: 60
# @tags: usage, tiff, python, info, compression, r18
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/info.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image
Image.new('RGB', (10, 10), (1, 2, 3)).save(sys.argv[1], 'TIFF', compression='tiff_lzw')

with Image.open(sys.argv[1]) as im:
    im.load()
    info = im.info
    assert isinstance(info, dict), type(info)
    assert 'compression' in info, ('keys', sorted(info))
    assert info['compression'] == 'tiff_lzw', ('compression', info['compression'])
print('ok compression=%s' % info['compression'])
PY
