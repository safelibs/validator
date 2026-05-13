#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r16-giftool-format-screen-and-version-pair
# @title: giftool -f '%v %s' treescap.gif emits version cookie and screen size jointly
# @description: Runs giftool with a multi-token format string "%v %s\n" against treescap.gif and asserts every emitted line is of the form "GIF8[79]a <W>,<H>" with positive width and height, exercising the simultaneous %v + %s emission contract (giftool renders %s as "W,H").
# @timeout: 60
# @tags: usage, cli, giftool, format
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -f '%v %s\n' <"$gif" >"$tmpdir/vs.txt"
[[ -s "$tmpdir/vs.txt" ]]

while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    [[ "$line" =~ ^GIF8[79]a\ [0-9]+,[0-9]+$ ]] || {
        printf 'bad line: %s\n' "$line" >&2
        exit 1
    }
done <"$tmpdir/vs.txt"
