#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r14-giftool-set-aspect-fire-roundtrip
# @title: giftool -a 64 sets pixel aspect byte readable via -f %a
# @description: Pipes fire.gif through giftool -a 64 to write a non-zero pixel-aspect byte into the logical screen descriptor, then reads it back via giftool -f '%a\n' and asserts every line reports 64, exercising the aspect-ratio mutation path.
# @timeout: 60
# @tags: usage, cli, giftool, aspect
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -a 64 <"$gif" >"$tmpdir/asp.gif"
file "$tmpdir/asp.gif" | grep -q 'GIF image data'

giftool -f '%a\n' <"$tmpdir/asp.gif" >"$tmpdir/a.txt"
[[ -s "$tmpdir/a.txt" ]]
unique=$(sort -u "$tmpdir/a.txt")
if [[ "$unique" != "64" ]]; then
    printf 'expected uniform aspect 64, got:\n%s\n' "$unique" >&2
    exit 1
fi
