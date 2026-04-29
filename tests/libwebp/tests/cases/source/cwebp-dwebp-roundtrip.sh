#!/usr/bin/env bash
# @testcase: cwebp-dwebp-roundtrip
# @title: cwebp dwebp round trip
# @description: Encodes a generated PPM image to WebP and decodes it.
# @timeout: 120
# @tags: cli, media

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
open(sys.argv[1],'wb').write(b'P6\n2 2\n255\n'+bytes([255,0,0,0,255,0,0,0,255,255,255,0]))
PY
cwebp -quiet "$tmpdir/in.ppm" -o "$tmpdir/a.webp"; dwebp "$tmpdir/a.webp" -ppm -o "$tmpdir/out.ppm"; head -n 3 "$tmpdir/out.ppm"
