#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-treescap-roundtrip
# @title: gifbuild treescap round trip
# @description: Dumps and rebuilds treescap.gif with gifbuild and validates the rebuilt GIF metadata.
# @timeout: 180
# @tags: usage, gif, roundtrip
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gifbuild-treescap-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"
gifbuild -d "$gif" >"$tmpdir/treescap.txt"
gifbuild "$tmpdir/treescap.txt" >"$tmpdir/rebuilt.gif"
giftext "$tmpdir/rebuilt.gif" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Screen Size'
