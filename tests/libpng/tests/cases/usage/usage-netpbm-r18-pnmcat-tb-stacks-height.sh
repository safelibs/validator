#!/usr/bin/env bash
# @testcase: usage-netpbm-r18-pnmcat-tb-stacks-height
# @title: netpbm pnmcat -tb of two PNG-derived images sums their heights
# @description: Concatenates two 3x2 PNG-decoded PGMs vertically with pnmcat -tb and asserts pamfile reports a "3 by 4" output, pinning height additivity through the libpng round trip.
# @timeout: 120
# @tags: usage, png, netpbm, pnmcat, r18
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for tag in a b; do
  cat >"$tmpdir/${tag}.pgm" <<EOF
P2
3 2
255
10 20 30
40 50 60
EOF
  pnmtopng "$tmpdir/${tag}.pgm" >"$tmpdir/${tag}.png"
done

pnmcat -tb \
  <(pngtopnm "$tmpdir/a.png") \
  <(pngtopnm "$tmpdir/b.png") >"$tmpdir/stack.pgm"

pamfile "$tmpdir/stack.pgm" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" '3 by 4'
