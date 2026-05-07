#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r13-giftool-set-position-fire-roundtrip
# @title: giftool -p 5,7 sets every frame's position and giftool -f reads it back
# @description: Pipes fire.gif through giftool -p 5,7 to set each frame's image-left/top to 5,7, then reads back via giftool -f '%p\n' and confirms every line reports the assigned 5,7 pair.
# @timeout: 60
# @tags: usage, cli, giftool, pipeline
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -p 5,7 <"$gif" >"$tmpdir/pos.gif"
file "$tmpdir/pos.gif" | grep -q 'GIF image data'

giftool -f '%p\n' <"$tmpdir/pos.gif" >"$tmpdir/p.txt"
[[ -s "$tmpdir/p.txt" ]]

unique=$(sort -u "$tmpdir/p.txt")
if [[ "$unique" != "5,7" ]]; then
    printf 'expected uniform position 5,7, got:\n%s\n' "$unique" >&2
    exit 1
fi
