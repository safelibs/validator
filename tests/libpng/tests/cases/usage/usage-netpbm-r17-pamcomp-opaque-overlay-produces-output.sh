#!/usr/bin/env bash
# @testcase: usage-netpbm-r17-pamcomp-opaque-overlay-produces-output
# @title: netpbm pamcomp composites a 2x2 overlay onto a 4x4 base via PNG-derived inputs
# @description: Builds a 4x4 base PPM and a 2x2 overlay PPM, runs pamcomp through pnm2png/png2pnm round trips, and asserts the result has dimensions "4 by 4" — exercising libpng-mediated alpha-free overlay composition.
# @timeout: 120
# @tags: usage, png, netpbm, pamcomp
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/base.ppm" 4 4 <<'PY'
import sys
W, H = int(sys.argv[2]), int(sys.argv[3])
b = bytes((20, 40, 60)) * (W * H)
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
python3 - "$tmpdir/over.ppm" 2 2 <<'PY'
import sys
W, H = int(sys.argv[2]), int(sys.argv[3])
b = bytes((200, 100, 50)) * (W * H)
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/base.ppm" >"$tmpdir/base.png"
pnmtopng "$tmpdir/over.ppm" >"$tmpdir/over.png"

pamcomp "$(pngtopnm "$tmpdir/over.png" >"$tmpdir/over-r.ppm" && printf '%s' "$tmpdir/over-r.ppm")" \
        "$(pngtopnm "$tmpdir/base.png" >"$tmpdir/base-r.ppm" && printf '%s' "$tmpdir/base-r.ppm")" \
        >"$tmpdir/out.ppm"

pamfile "$tmpdir/out.ppm" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" '4 by 4'
