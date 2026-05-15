#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r19-gifbuild-treescap-screen-colors-128
# @title: gifbuild -d on treescap.gif emits a "screen colors 128" line
# @description: Runs gifbuild -d on treescap.gif and asserts the produced text dump contains the literal line "screen colors 128", exercising the dump representation of the colour-resolution-derived screen colours field for the treescap fixture which advertises 7-bit colour resolution.
# @timeout: 60
# @tags: usage, cli, gifbuild, screen-colors, r19
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

gifbuild -d "$gif" >"$tmpdir/dump.txt"
validator_assert_contains "$tmpdir/dump.txt" 'screen colors 128'
