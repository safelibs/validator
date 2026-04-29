#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-grid-rgb
# @title: gif2rgb grid RGB output
# @description: Converts gifgrid.gif to a single RGB file and checks the byte count is nonzero.
# @timeout: 180
# @tags: usage, gif, conversion
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gif2rgb-grid-rgb"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"
gif2rgb -1 -o "$tmpdir/grid.rgb" "$gif"
test "$(wc -c <"$tmpdir/grid.rgb")" -gt 0
