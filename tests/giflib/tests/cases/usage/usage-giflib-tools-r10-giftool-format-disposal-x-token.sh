#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r10-giftool-format-disposal-x-token
# @title: giftool -f %x emits per-frame disposal mode for fire.gif
# @description: Asks giftool -f '%x\n' to print the GIF89 disposal mode for every frame of fire.gif and confirms the values are uniformly 1 (do-not-dispose), the encoded mode in the fixture's graphics control extensions.
# @timeout: 60
# @tags: usage, cli, giftool, format
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -f '%x\n' <"$gif" >"$tmpdir/disp.txt"

unique=$(sort -u "$tmpdir/disp.txt")
if [[ "$unique" != "1" ]]; then
    printf 'expected uniform disposal mode 1, got distinct values:\n' >&2
    sed -n '1,10p' "$tmpdir/disp.txt" >&2
    exit 1
fi

frames=$(wc -l <"$tmpdir/disp.txt")
[[ "$frames" -ge 5 ]]
