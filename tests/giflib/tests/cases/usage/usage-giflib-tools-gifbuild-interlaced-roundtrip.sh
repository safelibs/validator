#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-interlaced-roundtrip
# @title: gifbuild interlaced round trip
# @description: Dumps and rebuilds the interlaced treescap fixture with gifbuild and verifies the rebuilt GIF metadata.
# @timeout: 180
# @tags: usage, gif, roundtrip
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gifbuild-interlaced-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap-interlaced.gif"
validator_require_file "$gif"
gifbuild -d "$gif" >"$tmpdir/interlaced.txt"
gifbuild "$tmpdir/interlaced.txt" >"$tmpdir/rebuilt.gif"
giftext "$tmpdir/rebuilt.gif" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Screen Size'
