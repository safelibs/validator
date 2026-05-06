#!/usr/bin/env bash
# @testcase: usage-python3-pil-r9-tiff-tiffinfo-strip-count
# @title: tiffinfo reports Rows/Strip on Pillow output
# @description: Generates a TIFF via Pillow and verifies tiffinfo prints a Rows/Strip directory entry that matches the image height.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/strips.tiff" <<'PY'
import sys
from PIL import Image
Image.new("RGB", (32, 32), (10, 10, 10)).save(sys.argv[1], "TIFF")
PY

tiffinfo "$tmpdir/strips.tiff" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'Rows/Strip'
grep -Eq 'Rows/Strip:[[:space:]]+32' "$tmpdir/info.txt"
