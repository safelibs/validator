#!/usr/bin/env bash
# @testcase: usage-netpbm-r17-pamdeinterlace-odd-halves-height
# @title: netpbm pamdeinterlace -odd halves the height of a PNG-derived PGM
# @description: Runs pamdeinterlace -odd on a 4-row PGM round-tripped through libpng and asserts pamfile reports a 2-row output, pinning the odd-field extraction height behavior.
# @timeout: 120
# @tags: usage, png, netpbm, pamdeinterlace
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.pgm" <<'EOF'
P2
3 4
255
0 10 20
30 40 50
60 70 80
90 100 110
EOF

pnmtopng "$tmpdir/in.pgm" >"$tmpdir/in.png"
pngtopnm "$tmpdir/in.png" | pamdeinterlace -odd >"$tmpdir/out.pgm"

pamfile "$tmpdir/out.pgm" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" '3 by 2'
