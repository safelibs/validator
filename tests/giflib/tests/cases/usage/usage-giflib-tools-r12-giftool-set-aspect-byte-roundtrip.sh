#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r12-giftool-set-aspect-byte-roundtrip
# @title: giftool -d 50 sets per-frame delay readable via %d
# @description: Runs giftool -d 50 on fire.gif to set every frame's graphic-control delay to 50 (0.5 s), then re-reads the value through giftool -f '%d\n' and confirms every emitted line reports 50, exercising the per-frame delay mutation round-trip. (The -a aspect flag prints "unknown operation mode" on giflib 5.2.2; -d is the documented per-frame mutation surface.)
# @timeout: 60
# @tags: usage, cli, giftool, pipeline
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -d 50 <"$gif" >"$tmpdir/delayed.gif"
file "$tmpdir/delayed.gif" | grep -q 'GIF image data'

giftool -f '%d\n' <"$tmpdir/delayed.gif" >"$tmpdir/d.txt"
[[ -s "$tmpdir/d.txt" ]]
unique=$(sort -u "$tmpdir/d.txt")
if [[ "$unique" != "50" ]]; then
    printf 'expected uniform per-frame delay 50, got:\n' >&2
    sed -n '1,10p' "$tmpdir/d.txt" >&2
    exit 1
fi
