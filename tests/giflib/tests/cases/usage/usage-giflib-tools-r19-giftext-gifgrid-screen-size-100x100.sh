#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r19-giftext-gifgrid-screen-size-100x100
# @title: giftext on gifgrid.gif reports a 100x100 screen size line
# @description: Runs giftext on gifgrid.gif and asserts the rendered output contains the literal substring "Screen Size - Width = 100, Height = 100", exercising the screen-size header emission on the 100x100 grid fixture distinct from the treescap and fire fixtures.
# @timeout: 60
# @tags: usage, cli, giftext, screen-size, r19
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"

giftext "$gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'Width = 100, Height = 100'
