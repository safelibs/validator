#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r10-giftool-format-aspect-default-zero
# @title: giftool -f %a reports default zero pixel-aspect byte for fire.gif
# @description: Runs giftool -f '%a\n' against fire.gif and confirms the pixel aspect byte cookie evaluates to 0 on every frame, exercising the %a format directive against the unset aspect-ratio header field.
# @timeout: 60
# @tags: usage, cli, giftool, format
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -f '%a\n' <"$gif" >"$tmpdir/aspect.txt"

# Each line should be the literal "0" with no other values.
unique=$(sort -u "$tmpdir/aspect.txt")
if [[ "$unique" != "0" ]]; then
    printf 'expected single unique aspect byte "0", got:\n' >&2
    sed -n '1,10p' "$tmpdir/aspect.txt" >&2
    exit 1
fi

# Sanity: more than one frame in the multi-frame fire fixture.
lines=$(wc -l <"$tmpdir/aspect.txt")
[[ "$lines" -gt 1 ]]
