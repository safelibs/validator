#!/usr/bin/env bash
# @testcase: usage-giflib-tools-batch12-giffix-fire-passthrough
# @title: giffix passes a clean fire GIF through unchanged frames
# @description: Runs giffix on the clean fire fixture and verifies the output is a valid GIF with the same number of image frames as the input.
# @timeout: 60
# @tags: usage, cli, giffix
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giffix <"$gif" >"$tmpdir/fixed.gif"
file "$tmpdir/fixed.gif" | grep -q 'GIF image data'

frames_in=$(gifbuild -d "$gif" | grep -c '^Image ')
frames_out=$(gifbuild -d "$tmpdir/fixed.gif" | grep -c '^Image ')
[[ "$frames_in" -ge 1 ]]
[[ "$frames_in" == "$frames_out" ]]
