#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r10-giftool-format-user-input-default-zero
# @title: giftool -f %u prints zero user-input flag for unmodified fire.gif
# @description: Runs giftool -f '%u\n' on the fire.gif fixture without any prior modification and confirms the per-frame user-input flag is uniformly 0, exercising the %u format directive's default-state output.
# @timeout: 60
# @tags: usage, cli, giftool, format
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -f '%u\n' <"$gif" >"$tmpdir/user.txt"

unique=$(sort -u "$tmpdir/user.txt")
if [[ "$unique" != "0" ]]; then
    printf 'expected default user-input flag 0, got:\n' >&2
    sed -n '1,10p' "$tmpdir/user.txt" >&2
    exit 1
fi

frames=$(wc -l <"$tmpdir/user.txt")
[[ "$frames" -ge 5 ]]
