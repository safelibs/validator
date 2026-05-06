#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r10-gif2rgb-quantize-16-rgb-size-fire
# @title: gif2rgb -c 16 -1 -o produces width*height*3 RGB bytes for fire.gif
# @description: Runs gif2rgb -c 16 -1 -o to quantize fire.gif into a 16-color RGB stream and verifies the resulting raw RGB byte count equals width*height*3 reported by giftext, exercising the color-quantization output path while preserving raw-image dimensions.
# @timeout: 60
# @tags: usage, cli, gif2rgb, quantize
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

gif2rgb -c 16 -1 -o "$tmpdir/out.rgb" "$gif"
[[ -s "$tmpdir/out.rgb" ]]

giftext "$gif" >"$tmpdir/text.out"
size_line=$(grep -E 'Screen Size' "$tmpdir/text.out" | head -1)
w=$(echo "$size_line" | grep -oE '[0-9]+' | sed -n '1p')
h=$(echo "$size_line" | grep -oE '[0-9]+' | sed -n '2p')

[[ -n "$w" && -n "$h" ]]
expected=$((w * h * 3))
actual=$(stat -c '%s' "$tmpdir/out.rgb")
if [[ "$actual" != "$expected" ]]; then
    printf 'expected %d RGB bytes (%d x %d x 3), got %d\n' \
        "$expected" "$w" "$h" "$actual" >&2
    exit 1
fi
