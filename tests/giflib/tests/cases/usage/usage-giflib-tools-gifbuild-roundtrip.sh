#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-roundtrip
# @title: giflib-tools gifbuild roundtrip
# @description: Dumps a GIF fixture to gifbuild text and rebuilds it to verify the client can round trip image structure.
# @timeout: 180
# @tags: usage, cli, image
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"
gifbuild -d "$gif" >"$tmpdir/dump.txt"
gifbuild "$tmpdir/dump.txt" >"$tmpdir/rebuilt.gif"
giftext "$tmpdir/rebuilt.gif" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Screen Size'
