#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r12-gifclrmp-fire-palette-rgb-bounds
# @title: gifclrmp -s on fire.gif yields RGB triples within 0..255
# @description: Dumps the fire.gif palette via gifclrmp -s and asserts every row contains at least three numeric values, each in the 0..255 byte-range, exercising the palette dump formatter.
# @timeout: 60
# @tags: usage, cli, gifclrmp, palette
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

gifclrmp -s "$gif" >"$tmpdir/palette.txt"

count=$(wc -l <"$tmpdir/palette.txt")
[[ "$count" -ge 1 ]]

awk '
{
  if (NF < 3) { printf "row %d has fewer than 3 fields\n", NR > "/dev/stderr"; exit 1 }
  for (i = NF - 2; i <= NF; i++) {
    v = $i + 0
    if ($i !~ /^[0-9]+$/) { printf "row %d field %d non-numeric: %s\n", NR, i, $i > "/dev/stderr"; exit 1 }
    if (v < 0 || v > 255) { printf "row %d field %d out of range: %d\n", NR, i, v > "/dev/stderr"; exit 1 }
  }
}
' "$tmpdir/palette.txt"
