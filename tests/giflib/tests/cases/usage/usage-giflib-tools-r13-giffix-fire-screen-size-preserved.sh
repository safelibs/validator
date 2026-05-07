#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r13-giffix-fire-screen-size-preserved
# @title: giffix on fire.gif preserves the logical screen size
# @description: Runs giffix over fire.gif and confirms the output is still recognised as a GIF and reports the same screen size via giftool -f '%s\n' as the input, exercising giffix's clean-pass-through path.
# @timeout: 60
# @tags: usage, cli, giffix, screen
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giffix "$gif" >"$tmpdir/fixed.gif"
file "$tmpdir/fixed.gif" | grep -q 'GIF image data'
[[ -s "$tmpdir/fixed.gif" ]]

giftool -f '%s\n' <"$gif" | head -n 1 >"$tmpdir/s_in.txt"
giftool -f '%s\n' <"$tmpdir/fixed.gif" | head -n 1 >"$tmpdir/s_out.txt"

if ! diff -u "$tmpdir/s_in.txt" "$tmpdir/s_out.txt" >"$tmpdir/diff" 2>&1; then
    printf 'screen size changed by giffix:\n' >&2
    cat "$tmpdir/diff" >&2
    exit 1
fi
