#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-grid-roundtrip
# @title: gifbuild grid round trip
# @description: Dumps and rebuilds gifgrid.gif with gifbuild and verifies the rebuilt GIF metadata remains readable.
# @timeout: 180
# @tags: usage, gif, roundtrip
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gifbuild-grid-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"
gifbuild -d "$gif" >"$tmpdir/grid.txt"
gifbuild "$tmpdir/grid.txt" >"$tmpdir/rebuilt.gif"
giftext "$tmpdir/rebuilt.gif" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Screen Size'
