#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r10-giftool-zero-delay-clears-all-frames
# @title: giftool -d 0 zeroes the GCB delay on every frame of fire.gif
# @description: Pipes fire.gif through giftool -d 0 to clear the per-frame delay, then re-reads the delay through a second giftool -f '%d\n' pass and confirms every frame reports delay=0 instead of the original 5-centisecond value.
# @timeout: 60
# @tags: usage, cli, giftool, pipeline
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

# Sanity: the original fixture must have a non-zero delay, otherwise the
# test of the -d 0 mutation is vacuous.
giftool -f '%d\n' <"$gif" >"$tmpdir/before.txt"
before_unique=$(sort -u "$tmpdir/before.txt")
if [[ "$before_unique" == "0" ]]; then
    printf 'fire.gif unexpectedly has zero delay before mutation:\n' >&2
    sed -n '1,5p' "$tmpdir/before.txt" >&2
    exit 1
fi

giftool -d 0 <"$gif" >"$tmpdir/zero.gif"
file "$tmpdir/zero.gif" | grep -q 'GIF image data'

giftool -f '%d\n' <"$tmpdir/zero.gif" >"$tmpdir/after.txt"
after_unique=$(sort -u "$tmpdir/after.txt")
if [[ "$after_unique" != "0" ]]; then
    printf 'expected uniform delay 0 after -d 0, got:\n' >&2
    sed -n '1,10p' "$tmpdir/after.txt" >&2
    exit 1
fi

# Frame count must be preserved.
before_count=$(wc -l <"$tmpdir/before.txt")
after_count=$(wc -l <"$tmpdir/after.txt")
[[ "$before_count" == "$after_count" ]]
