#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r15-giftool-set-userinput-one-treescap
# @title: giftool -u 1 sets the user-input flag on every treescap frame
# @description: Pipes treescap.gif through giftool -u 1 to set the GCB user-input flag on every frame, then reads back via giftool -f '%u\n' and asserts every line equals "1", exercising the user-input setter on a non-interlaced fixture.
# @timeout: 60
# @tags: usage, cli, giftool, userinput
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -u 1 <"$gif" >"$tmpdir/u.gif"
file "$tmpdir/u.gif" | grep -q 'GIF image data'

giftool -f '%u\n' <"$tmpdir/u.gif" >"$tmpdir/u.txt"
unique=$(sort -u "$tmpdir/u.txt")
if [[ "$unique" != "1" ]]; then
    printf 'expected uniform user-input 1, got:\n%s\n' "$unique" >&2
    exit 1
fi
