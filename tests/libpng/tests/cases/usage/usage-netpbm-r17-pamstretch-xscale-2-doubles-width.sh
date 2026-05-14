#!/usr/bin/env bash
# @testcase: usage-netpbm-r17-pamstretch-xscale-2-doubles-width
# @title: netpbm pamstretch -xscale 2 -yscale 1 doubles width and preserves height
# @description: Stretches a 4x3 PNG-derived PGM with pamstretch -xscale 2 -yscale 1 and asserts pamfile reports an 8x3 output via "8 by 3", pinning Ubuntu netpbm's directional scaling factor behavior.
# @timeout: 120
# @tags: usage, png, netpbm, pamstretch
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.pgm" <<'EOF'
P2
4 3
255
0 30 60 90
120 150 180 210
50 70 90 110
EOF

pnmtopng "$tmpdir/in.pgm" >"$tmpdir/in.png"
pngtopnm "$tmpdir/in.png" | pamstretch -xscale 2 -yscale 1 >"$tmpdir/out.pgm"

pamfile "$tmpdir/out.pgm" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" '8 by 3'
