#!/usr/bin/env bash
# @testcase: usage-python3-pil-r10-tiff-tiff2ps-postscript-magic
# @title: tiff2ps emits a PostScript stream from a Pillow TIFF
# @description: Saves an RGB TIFF with Pillow, runs tiff2ps to convert it, and verifies the output begins with the %!PS-Adobe magic and contains a %%BoundingBox header.
# @timeout: 180
# @tags: usage, tiff, python, tiff2ps
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/in.tiff"
ps="$tmpdir/out.ps"

python3 - "$src" <<'PY'
import sys
from PIL import Image
img = Image.new("RGB", (16, 12), (40, 80, 120))
img.save(sys.argv[1], "TIFF")
PY

validator_require_file "$src"
tiff2ps "$src" >"$ps"
validator_require_file "$ps"

head -c 16 "$ps" | grep -q '^%!PS-Adobe-'
validator_assert_contains "$ps" '%%BoundingBox'
