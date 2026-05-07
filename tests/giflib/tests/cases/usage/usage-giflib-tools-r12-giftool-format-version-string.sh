#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r12-giftool-format-version-string
# @title: giftool -f %v reports a GIF87a or GIF89a version per frame for fire.gif
# @description: Asks giftool -f '%v\n' to print the GIF version string for every frame of fire.gif and confirms the output is a non-empty list of GIF8[79]a values, exercising the version-format cookie path.
# @timeout: 60
# @tags: usage, cli, giftool, format
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -f '%v\n' <"$gif" >"$tmpdir/ver.txt"

# Every line must be either GIF87a or GIF89a.
if grep -vqE '^GIF8[79]a$' "$tmpdir/ver.txt"; then
    printf 'unexpected version line(s) in giftool %%v output:\n' >&2
    sed -n '1,10p' "$tmpdir/ver.txt" >&2
    exit 1
fi

# Multi-frame fire fixture should print at least one row.
frames=$(wc -l <"$tmpdir/ver.txt")
[[ "$frames" -ge 1 ]]
