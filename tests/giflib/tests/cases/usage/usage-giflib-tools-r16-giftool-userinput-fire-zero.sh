#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r16-giftool-userinput-fire-zero
# @title: giftool -u 0 fire.gif clears the user-input flag on every frame
# @description: Pipes fire.gif through giftool -u 0 to clear the graphics-control-block user-input flag on every frame, then re-reads via giftool -f '%u\n' and confirms every frame reports 0, exercising the user-input clear path complementing the existing -u 1 set test.
# @timeout: 60
# @tags: usage, cli, giftool, userinput
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -u 0 <"$gif" >"$tmpdir/u.gif"
file "$tmpdir/u.gif" | grep -q 'GIF image data'

giftool -f '%u\n' <"$tmpdir/u.gif" >"$tmpdir/u.txt"
[[ -s "$tmpdir/u.txt" ]]
unique=$(sort -u "$tmpdir/u.txt")
[[ "$unique" == "0" ]] || {
    printf 'expected uniform user-input 0, got:\n%s\n' "$unique" >&2
    exit 1
}
