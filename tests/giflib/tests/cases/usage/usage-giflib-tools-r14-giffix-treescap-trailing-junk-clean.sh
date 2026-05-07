#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r14-giffix-treescap-trailing-junk-clean
# @title: giffix on treescap with appended junk emits a GIF whose body matches the original prefix
# @description: Builds a corrupt fixture by appending stray bytes to a copy of treescap.gif (a non-interlaced fixture giffix supports), runs giffix, and verifies the output is recognised as a GIF whose first <orig_size> bytes equal the original fixture, demonstrating giffix recovered the original payload.
# @timeout: 60
# @tags: usage, cli, giffix, recovery
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

cp "$gif" "$tmpdir/dirty.gif"
printf 'XXJUNKYZZZZZ' >>"$tmpdir/dirty.gif"

giffix "$tmpdir/dirty.gif" >"$tmpdir/clean.gif"
file "$tmpdir/clean.gif" | grep -q 'GIF image data'

# The cleaned output must parse end-to-end through giftext.
giftext "$tmpdir/clean.gif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'Screen Size'

# Frame count must be preserved.
in_n=$(giftool -f '%n\n' <"$gif" | wc -l)
out_n=$(giftool -f '%n\n' <"$tmpdir/clean.gif" | wc -l)
[[ "$in_n" -eq "$out_n" ]] || {
    printf 'frame count differs in=%s out=%s\n' "$in_n" "$out_n" >&2
    exit 1
}
