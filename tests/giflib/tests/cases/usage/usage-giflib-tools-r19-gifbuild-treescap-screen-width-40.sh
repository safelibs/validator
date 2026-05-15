#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r19-gifbuild-treescap-screen-width-40
# @title: gifbuild -d on treescap.gif emits a "screen width 40" line in its dump
# @description: Runs gifbuild -d on treescap.gif and asserts the produced dump contains the literal line "screen width 40", exercising the dump representation of the screen-width header field on the 40x40 fixture distinct from prior dump line-count tests.
# @timeout: 60
# @tags: usage, cli, gifbuild, dump, r19
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

gifbuild -d "$gif" >"$tmpdir/dump.txt"
validator_assert_contains "$tmpdir/dump.txt" 'screen width 40'
validator_assert_contains "$tmpdir/dump.txt" 'screen height 40'
