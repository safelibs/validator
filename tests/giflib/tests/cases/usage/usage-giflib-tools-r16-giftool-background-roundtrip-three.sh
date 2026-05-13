#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r16-giftool-background-roundtrip-three
# @title: giftool -b 3 fire.gif round-trips through giftool -f '%b\n'
# @description: Applies giftool -b 3 to fire.gif to overwrite the logical-screen background color index, reads it back via giftool -f '%b\n', and asserts every emitted line equals "3", exercising the background-index mutation surface at a non-default value.
# @timeout: 60
# @tags: usage, cli, giftool, background
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -b 3 <"$gif" >"$tmpdir/out.gif"
file "$tmpdir/out.gif" | grep -q 'GIF image data'

giftool -f '%b\n' <"$tmpdir/out.gif" >"$tmpdir/b.txt"
[[ -s "$tmpdir/b.txt" ]]
unique=$(sort -u "$tmpdir/b.txt")
[[ "$unique" == "3" ]] || {
    printf 'expected uniform %%b == 3, got:\n%s\n' "$unique" >&2
    exit 1
}
