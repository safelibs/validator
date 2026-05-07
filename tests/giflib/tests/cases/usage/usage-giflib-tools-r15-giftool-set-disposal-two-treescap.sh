#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r15-giftool-set-disposal-two-treescap
# @title: giftool -x 2 sets disposal mode background on every treescap frame
# @description: Pipes treescap.gif through giftool -x 2 to set disposal mode 2 (restore-to-background) on every frame, then reads back via giftool -f '%x\n' and asserts every line equals "2", exercising the disposal-mode setter at a non-default value.
# @timeout: 60
# @tags: usage, cli, giftool, disposal
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -x 2 <"$gif" >"$tmpdir/x.gif"
file "$tmpdir/x.gif" | grep -q 'GIF image data'

giftool -f '%x\n' <"$tmpdir/x.gif" >"$tmpdir/x.txt"
unique=$(sort -u "$tmpdir/x.txt")
if [[ "$unique" != "2" ]]; then
    printf 'expected uniform disposal 2, got:\n%s\n' "$unique" >&2
    exit 1
fi
