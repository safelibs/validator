#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r20-gifbuild-treescap-screen-height-40
# @title: gifbuild -d on treescap.gif emits a "screen height 40" line
# @description: Runs gifbuild -d on the 40x40 treescap.gif fixture and asserts the dump contains the literal line "screen height 40", exercising the screen-height field in the textual dump distinct from the existing r19 "screen width 40" assertion.
# @timeout: 60
# @tags: usage, cli, gifbuild, screen-height, r20
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

gifbuild -d "$gif" >"$tmpdir/dump.txt"
validator_assert_contains "$tmpdir/dump.txt" 'screen height 40'
