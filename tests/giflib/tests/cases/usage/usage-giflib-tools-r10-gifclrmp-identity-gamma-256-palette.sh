#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r10-gifclrmp-identity-gamma-256-palette
# @title: gifclrmp -g 1.0 then -s on fire.gif yields a 256-entry palette dump
# @description: Applies gifclrmp -g 1.0 (identity gamma) to fire.gif, then dumps the palette of the resulting GIF with gifclrmp -s and confirms the dump has exactly 256 entries each carrying three RGB integers, exercising the gamma-mutation path with an identity transform.
# @timeout: 60
# @tags: usage, cli, gifclrmp, gamma
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

gifclrmp -g 1.0 "$gif" >"$tmpdir/identity.gif"
file "$tmpdir/identity.gif" | grep -q 'GIF image data'

gifclrmp -s "$tmpdir/identity.gif" >"$tmpdir/palette.txt"

count=$(wc -l <"$tmpdir/palette.txt")
if [[ "$count" != 256 ]]; then
    printf 'expected 256 palette rows, got %s\n' "$count" >&2
    sed -n '1,5p' "$tmpdir/palette.txt" >&2
    exit 1
fi

# Each row should report at least three integers (index plus R G B).
awk '{ if (NF < 3) { exit 1 } }' "$tmpdir/palette.txt"
