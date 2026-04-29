#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-grid-planar-equal-channels
# @title: gif2rgb grid planar equal channels
# @description: Decodes gifgrid.gif with gif2rgb planar output and verifies that the R, G, and B planes have equal nonzero byte sizes.
# @timeout: 180
# @tags: usage, gif, gif2rgb
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gif2rgb-grid-planar-equal-channels"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

color_row() {
  grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$1"
}

gif2rgb -o "$tmpdir/grid" "$samples/gifgrid.gif"
validator_require_file "$tmpdir/grid.R"
validator_require_file "$tmpdir/grid.G"
validator_require_file "$tmpdir/grid.B"
size_r=$(wc -c <"$tmpdir/grid.R")
size_g=$(wc -c <"$tmpdir/grid.G")
size_b=$(wc -c <"$tmpdir/grid.B")
test "$size_r" -gt 0
test "$size_r" -eq "$size_g"
test "$size_g" -eq "$size_b"
