#!/usr/bin/env bash
# @testcase: usage-python3-pil-r10-tiff-tiffcmp-equal-files
# @title: tiffcmp returns success on byte-equal Pillow TIFF copies
# @description: Saves an RGB TIFF with Pillow, copies it to a second file, and verifies tiffcmp exits 0 with no diff lines printed.
# @timeout: 180
# @tags: usage, tiff, python, tiffcmp
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

a="$tmpdir/a.tiff"
b="$tmpdir/b.tiff"

python3 - "$a" <<'PY'
import sys
from PIL import Image
img = Image.new("RGB", (24, 16))
img.putdata([((x * 11) % 256, (y * 13) % 256, ((x + y) * 5) % 256)
             for y in range(16) for x in range(24)])
img.save(sys.argv[1], "TIFF")
PY

cp -- "$a" "$b"
out="$tmpdir/cmp.txt"
tiffcmp "$a" "$b" >"$out" 2>&1
[[ ! -s "$out" ]] || { sed -n '1,40p' "$out" >&2; exit 1; }
