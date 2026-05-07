#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r14-giftool-format-info-pair-treescap
# @title: giftool -f '%w %h' reports treescap dimensions on every frame
# @description: Runs giftool -f '%w %h\n' against treescap.gif and asserts every per-frame line is "40 40" (treescap is a static 40x40 frame), exercising the per-frame width and height format directives in tandem.
# @timeout: 60
# @tags: usage, cli, giftool, format
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -f '%w %h\n' <"$gif" >"$tmpdir/wh.txt"

[[ -s "$tmpdir/wh.txt" ]]
unique=$(sort -u "$tmpdir/wh.txt")
if [[ "$unique" != "40 40" ]]; then
    printf 'expected uniform "40 40", got:\n%s\n' "$unique" >&2
    exit 1
fi
