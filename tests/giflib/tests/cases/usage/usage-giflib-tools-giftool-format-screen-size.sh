#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-format-screen-size
# @title: giftool -f formatter prints screen size
# @description: Exercises the giftool -f format directive to print version and screen size cookies for a single-image fixture.
# @timeout: 60
# @tags: usage, cli, giftool
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftool -f 'version=%v size=%wx%h screen=%s\n' <"$gif" >"$tmpdir/out.txt"
[[ "$(wc -l <"$tmpdir/out.txt")" -eq 1 ]]
grep -Fxq 'version=GIF87a size=40x40 screen=40,40' "$tmpdir/out.txt"
