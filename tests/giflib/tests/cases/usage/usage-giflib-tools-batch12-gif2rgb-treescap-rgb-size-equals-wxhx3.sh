#!/usr/bin/env bash
# @testcase: usage-giflib-tools-batch12-gif2rgb-treescap-rgb-size-equals-wxhx3
# @title: gif2rgb output size matches treescap pixel count
# @description: Runs gif2rgb -1 on the treescap GIF and verifies the raw RGB byte count equals width*height*3 reported by giftext.
# @timeout: 60
# @tags: usage, cli, gif2rgb
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

gif2rgb -1 -o "$tmpdir/out.rgb" "$gif"

giftext "$gif" >"$tmpdir/text.out"
size_line=$(grep -E 'Screen Size' "$tmpdir/text.out" | head -1)
w=$(echo "$size_line" | grep -oE '[0-9]+' | sed -n '1p')
h=$(echo "$size_line" | grep -oE '[0-9]+' | sed -n '2p')

[[ -n "$w" && -n "$h" ]]
expected=$((w * h * 3))
actual=$(stat -c '%s' "$tmpdir/out.rgb")
[[ "$actual" == "$expected" ]]
