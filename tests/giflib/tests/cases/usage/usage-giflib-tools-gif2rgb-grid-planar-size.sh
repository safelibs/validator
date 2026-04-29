#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-grid-planar-size
# @title: gif2rgb grid planar size
# @description: Converts gifgrid.gif to planar RGB files with gif2rgb and verifies the three color planes have matching nonzero sizes.
# @timeout: 180
# @tags: usage, gif, image
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gif2rgb-grid-planar-size"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"
gif2rgb -o "$tmpdir/grid" "$gif"
size_r=$(wc -c <"$tmpdir/grid.R")
size_g=$(wc -c <"$tmpdir/grid.G")
size_b=$(wc -c <"$tmpdir/grid.B")
test "$size_r" -gt 0
test "$size_r" -eq "$size_g"
test "$size_g" -eq "$size_b"
