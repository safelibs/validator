#!/usr/bin/env bash
# @testcase: usage-pngquant-r21-skip-if-larger-keeps-bigger-original
# @title: pngquant --skip-if-larger on a 2x2 paletted input exits nonzero (skipped)
# @description: Generates a tiny 2x2 paletted PNG (already small) and runs pngquant 256 --skip-if-larger; asserts the command exits with a nonzero status indicating pngquant skipped writing the new file because it would not be smaller, pinning libpng's size-comparison gating in pngquant.
# @timeout: 120
# @tags: usage, png, pngquant, skip-if-larger, r21
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 2, 2
b = bytearray([255, 0, 0,  0, 255, 0,  0, 0, 255,  255, 255, 0])
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

set +e
pngquant 256 --skip-if-larger --output "$tmpdir/out.png" "$tmpdir/in.png" >"$tmpdir/log.txt" 2>&1
rc=$?
set -e
[[ $rc -ne 0 ]] || { echo "expected nonzero exit (skipped), got 0" >&2; sed -n '1,80p' "$tmpdir/log.txt" >&2; exit 1; }
