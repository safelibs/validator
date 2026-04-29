#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-fire-roundtrip
# @title: gifbuild fire round trip
# @description: Dumps and rebuilds fire.gif with gifbuild and validates the rebuilt GIF metadata.
# @timeout: 180
# @tags: usage, gif, roundtrip
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-giflib-tools-gifbuild-fire-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"
gifbuild -d "$gif" >"$tmpdir/fire.txt"
gifbuild "$tmpdir/fire.txt" >"$tmpdir/rebuilt.gif"
giftext "$tmpdir/rebuilt.gif" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Screen Size'
