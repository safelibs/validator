#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-grid-roundtrip-colormap
# @title: gifbuild grid round trip color map
# @description: Exercises gifbuild grid round trip color map through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gifbuild-grid-roundtrip-colormap"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

samples="$VALIDATOR_SAMPLE_ROOT/pic"
tests_root="$VALIDATOR_SAMPLE_ROOT/tests"

gifbuild -d "$samples/gifgrid.gif" >"$tmpdir/grid.txt"
gifbuild "$tmpdir/grid.txt" >"$tmpdir/grid.gif"
gifclrmp "$tmpdir/grid.gif" | tee "$tmpdir/out"
grep -Eq '^[[:space:]]*0[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+' "$tmpdir/out"
