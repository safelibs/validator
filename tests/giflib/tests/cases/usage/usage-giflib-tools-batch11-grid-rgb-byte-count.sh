#!/usr/bin/env bash
# @testcase: usage-giflib-tools-batch11-grid-rgb-byte-count
# @title: gif2rgb grid RGB byte count
# @description: Converts the grid fixture to packed RGB and checks the byte count is channel-aligned.
# @timeout: 180
# @tags: usage, gif, cli
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-batch11-grid-rgb-byte-count"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

require_nonempty() {
  test "$(wc -c <"$1")" -gt 0
}

gif2rgb -1 -o "$tmpdir/grid.rgb" "$samples/gifgrid.gif"
size=$(wc -c <"$tmpdir/grid.rgb")
test "$size" -gt 1000
test $((size % 3)) -eq 0
