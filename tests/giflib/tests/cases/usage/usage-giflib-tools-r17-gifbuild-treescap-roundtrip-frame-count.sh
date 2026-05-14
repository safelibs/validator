#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r17-gifbuild-treescap-roundtrip-frame-count
# @title: gifbuild round-trip through treescap.gif preserves the per-frame count
# @description: Dumps treescap.gif via gifbuild -d, reconstructs via gifbuild, and asserts the rebuilt GIF reports the same per-frame count under giftool -f '%n\n' as the source, exercising the textual-dump-and-rebuild pipeline.
# @timeout: 60
# @tags: usage, cli, gifbuild, roundtrip
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

gifbuild -d "$gif" >"$tmpdir/dump.txt"
[[ -s "$tmpdir/dump.txt" ]]

gifbuild "$tmpdir/dump.txt" >"$tmpdir/rebuilt.gif"
file "$tmpdir/rebuilt.gif" | grep -q 'GIF image data'

in_n=$(giftool -f '%n\n' <"$gif" | wc -l)
out_n=$(giftool -f '%n\n' <"$tmpdir/rebuilt.gif" | wc -l)
[[ "$in_n" -eq "$out_n" ]] || {
    printf 'frame count differs in=%s out=%s\n' "$in_n" "$out_n" >&2
    exit 1
}
