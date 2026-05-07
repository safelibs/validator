#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r13-giftool-format-userinput-default-zero-treescap
# @title: giftool -f %u reports zero user-input flag for every treescap frame
# @description: Runs giftool -f '%u\n' on treescap.gif and asserts every line is the digit 0, confirming the default user-input flag is unset on the fixture's frames, exercising the format cookie %u path.
# @timeout: 60
# @tags: usage, cli, giftool, format
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -f '%u\n' <"$gif" >"$tmpdir/u.txt"

[[ -s "$tmpdir/u.txt" ]]
unique=$(sort -u "$tmpdir/u.txt")
if [[ "$unique" != "0" ]]; then
    printf 'expected uniform user-input 0, got:\n%s\n' "$unique" >&2
    exit 1
fi
