#!/usr/bin/env bash
# @testcase: usage-python3-pil-r11-tiff-tiffsplit-prefix-output-naming
# @title: tiffsplit with explicit prefix produces aaa/aab/aac single-image files
# @description: Builds a 3-page TIFF and runs tiffsplit with an explicit prefix; verifies the resulting files are named "<prefix>aaa.tif", "<prefix>aab.tif", "<prefix>aac.tif" (libtiff's deterministic alphabetic suffix sequence) and each contains exactly one TIFF directory.
# @timeout: 60
# @tags: usage, tiff, tiffsplit, naming
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/multi.tif"

python3 - "$src" <<'PY'
import sys
from PIL import Image
im = Image.new('RGB', (40, 30), (10, 20, 30))
im.save(sys.argv[1], 'TIFF', save_all=True, append_images=[im, im])
PY

tiffsplit "$src" "$tmpdir/page" >/dev/null

[[ -f "$tmpdir/pageaaa.tif" ]]
[[ -f "$tmpdir/pageaab.tif" ]]
[[ -f "$tmpdir/pageaac.tif" ]]
[[ ! -f "$tmpdir/pageaad.tif" ]]

for f in "$tmpdir"/page*.tif; do
    count=$(tiffinfo "$f" | grep -c '^TIFF Directory')
    [[ "$count" == "1" ]] || { echo "expected 1 directory in $f, got $count" >&2; exit 1; }
done
