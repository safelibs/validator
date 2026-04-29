#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-fire-planar-size
# @title: gif2rgb fire planar sizes
# @description: Converts the fire fixture to planar RGB output with gif2rgb and verifies all three channel files have equal non-zero size.
# @timeout: 180
# @tags: usage, gif, gif2rgb
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gif2rgb-fire-planar-size"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"

color_row() {
  grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$1"
}

gif2rgb -o "$tmpdir/fire" "$samples/fire.gif"
size_r=$(wc -c <"$tmpdir/fire.R")
size_g=$(wc -c <"$tmpdir/fire.G")
size_b=$(wc -c <"$tmpdir/fire.B")
test "$size_r" -gt 0
test "$size_r" -eq "$size_g"
test "$size_g" -eq "$size_b"
