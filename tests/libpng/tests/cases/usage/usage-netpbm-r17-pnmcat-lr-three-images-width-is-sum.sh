#!/usr/bin/env bash
# @testcase: usage-netpbm-r17-pnmcat-lr-three-images-width-is-sum
# @title: netpbm pnmcat -lr concatenation of three images yields width equal to sum
# @description: Joins three PNG-derived 2x2 grayscale images horizontally via pnmcat -lr and asserts the resulting pamfile listing shows "6 by 2", verifying width additivity across three inputs through the libpng round trip.
# @timeout: 120
# @tags: usage, png, netpbm, pnmcat
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for tag in a b c; do
  cat >"$tmpdir/${tag}.pgm" <<EOF
P2
2 2
255
10 20
30 40
EOF
  pnmtopng "$tmpdir/${tag}.pgm" >"$tmpdir/${tag}.png"
done

pnmcat -lr \
  <(pngtopnm "$tmpdir/a.png") \
  <(pngtopnm "$tmpdir/b.png") \
  <(pngtopnm "$tmpdir/c.png") >"$tmpdir/joined.pgm"

pamfile "$tmpdir/joined.pgm" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" '6 by 2'
