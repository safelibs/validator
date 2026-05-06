#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r10-giftool-set-delay-50-uniform
# @title: giftool -d 50 sets every fire.gif frame to a 50-cs delay
# @description: Pipes fire.gif through giftool -d 50 and confirms a follow-up giftool -f '%d\n' pass reports a uniform delay of 50 centiseconds across every frame, exercising the delay-mutation path against the multi-frame fire fixture.
# @timeout: 60
# @tags: usage, cli, giftool, pipeline
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -d 50 <"$gif" >"$tmpdir/d50.gif"
file "$tmpdir/d50.gif" | grep -q 'GIF image data'

giftool -f '%d\n' <"$tmpdir/d50.gif" >"$tmpdir/d.txt"
unique=$(sort -u "$tmpdir/d.txt")
if [[ "$unique" != "50" ]]; then
    printf 'expected uniform delay 50, got:\n' >&2
    sed -n '1,10p' "$tmpdir/d.txt" >&2
    exit 1
fi

# Cross-check via gifbuild dump for at least one "delay 50" line.
gifbuild -d "$tmpdir/d50.gif" >"$tmpdir/dump.txt"
count=$(grep -cE '^[[:space:]]*delay 50$' "$tmpdir/dump.txt")
[[ "$count" -ge 1 ]]
