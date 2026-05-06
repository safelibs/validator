#!/usr/bin/env bash
# @testcase: usage-giflib-tools-batch12-gifbuild-fire-version-line
# @title: gifbuild -d emits screen width and height for fire
# @description: Runs gifbuild -d on the fire fixture and verifies the textual dump contains "screen width" and "screen height" header lines.
# @timeout: 60
# @tags: usage, cli, gifbuild
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

gifbuild -d "$gif" >"$tmpdir/dump.txt"
validator_assert_contains "$tmpdir/dump.txt" 'screen width'
validator_assert_contains "$tmpdir/dump.txt" 'screen height'
validator_assert_contains "$tmpdir/dump.txt" 'screen colors'
