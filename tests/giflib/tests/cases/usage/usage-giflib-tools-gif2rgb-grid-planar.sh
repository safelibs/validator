#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-grid-planar
# @title: gif2rgb grid planar output
# @description: Converts gifgrid.gif to planar RGB files and verifies each channel file exists.
# @timeout: 180
# @tags: usage, gif, conversion
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gif2rgb-grid-planar"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"
gif2rgb -o "$tmpdir/grid" "$gif"
validator_require_file "$tmpdir/grid.R"
validator_require_file "$tmpdir/grid.G"
validator_require_file "$tmpdir/grid.B"
wc -c "$tmpdir/grid.R" "$tmpdir/grid.G" "$tmpdir/grid.B"
