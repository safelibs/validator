#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r16-giftool-delay-mutation-fire-fifteen
# @title: giftool -d 15 fire.gif round-trips through giftool -f '%d\n'
# @description: Pipes fire.gif through giftool -d 15 to overwrite per-frame delay-time, then reads back via giftool -f '%d\n' and asserts every line reports 15 centiseconds, exercising the delay setter at a value distinct from those used by other batches (5, 25, 50, 75).
# @timeout: 60
# @tags: usage, cli, giftool, delay
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -d 15 <"$gif" >"$tmpdir/d.gif"
file "$tmpdir/d.gif" | grep -q 'GIF image data'

giftool -f '%d\n' <"$tmpdir/d.gif" >"$tmpdir/d.txt"
[[ -s "$tmpdir/d.txt" ]]
unique=$(sort -u "$tmpdir/d.txt")
[[ "$unique" == "15" ]] || {
    printf 'expected uniform delay 15, got:\n%s\n' "$unique" >&2
    exit 1
}
