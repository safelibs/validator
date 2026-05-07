#!/usr/bin/env bash
# @testcase: usage-python3-pil-r12-tiff-software-and-imagedescription-tags
# @title: PIL TIFF Software (305) and ImageDescription (270) round-trip via tiffinfo
# @description: Saves a TIFF with explicit Software and ImageDescription string tags via Pillow's tiffinfo argument and verifies tiffinfo reports both lines verbatim and Pillow re-reads tag_v2[305] and tag_v2[270] with the same values.
# @timeout: 60
# @tags: usage, tiff, python, tags, ascii
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

path="$tmpdir/ascii_tags.tif"

python3 - "$path" <<'PY'
import sys
from PIL import Image, TiffImagePlugin
img = Image.new('RGB', (16, 16), (40, 80, 120))
info = TiffImagePlugin.ImageFileDirectory_v2()
info[270] = 'r12 description'
info[305] = 'r12-software'
img.save(sys.argv[1], 'TIFF', tiffinfo=info)

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.tag_v2.get(270) == 'r12 description', ('ImageDescription', im.tag_v2.get(270))
    assert im.tag_v2.get(305) == 'r12-software', ('Software', im.tag_v2.get(305))
PY

tiffinfo "$path" >"$tmpdir/info.out"
grep -E 'ImageDescription: r12 description' "$tmpdir/info.out" >/dev/null
grep -E 'Software: r12-software' "$tmpdir/info.out" >/dev/null
