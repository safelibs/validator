#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r21-giftext-treescap-sort-flag-off
# @title: giftext -c on treescap.gif reports Global Color Map "Sort Flag: off"
# @description: Runs giftext -c on treescap.gif (the -c flag enables colormap dumping with the sort-flag line) and asserts the textual dump contains the literal line "Sort Flag: off", exercising the giftext narrative emission of the color-table sort-flag bit distinct from the existing giftool -f %z numeric format-code test on fire.gif.
# @timeout: 60
# @tags: usage, cli, giftext, sort-flag, r21
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftext -c "$gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'Sort Flag: off'
validator_assert_contains "$tmpdir/info.txt" 'Global Color Map'
