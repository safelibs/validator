#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r10-giftool-double-position-last-wins
# @title: chained giftool -p calls let the last position override the first
# @description: Pipes fire.gif through giftool -p 5,5 then giftool -p 11,13 and confirms the final %p format readout reports 11,13 on every frame, exercising chained-pipeline override semantics for the position field.
# @timeout: 60
# @tags: usage, cli, giftool, pipeline
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -p 5,5 <"$gif" \
    | giftool -p 11,13 \
    >"$tmpdir/double.gif"

file "$tmpdir/double.gif" | grep -q 'GIF image data'

giftool -f '%p\n' <"$tmpdir/double.gif" >"$tmpdir/pos.txt"
unique=$(sort -u "$tmpdir/pos.txt")
if [[ "$unique" != "11,13" ]]; then
    printf 'expected uniform position 11,13 after override, got:\n' >&2
    sed -n '1,10p' "$tmpdir/pos.txt" >&2
    exit 1
fi

# Cross-check via gifbuild dump that the new origin is recorded.
gifbuild -d "$tmpdir/double.gif" >"$tmpdir/dump.txt"
grep -qE '^[[:space:]]*image left 11$' "$tmpdir/dump.txt"
grep -qE '^[[:space:]]*image top 13$' "$tmpdir/dump.txt"
