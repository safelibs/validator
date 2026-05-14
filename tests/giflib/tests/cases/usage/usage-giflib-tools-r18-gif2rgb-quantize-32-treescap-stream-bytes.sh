#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r18-gif2rgb-quantize-32-treescap-stream-bytes
# @title: gif2rgb -c 32 -1 -o on treescap.gif produces width*height*3 RGB bytes
# @description: Runs gif2rgb -c 32 -1 -o on treescap.gif to quantize the image to 32 colors as a single concatenated RGB stream and asserts the resulting raw byte count equals 40*40*3 (4800) bytes, exercising the quantize-plus-stream output path with a color count not covered by existing tests on this fixture.
# @timeout: 60
# @tags: usage, cli, gif2rgb, quantize, r18
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

gif2rgb -c 32 -1 -o "$tmpdir/q.rgb" "$gif"
[[ -s "$tmpdir/q.rgb" ]]
size=$(stat -c '%s' "$tmpdir/q.rgb")
if [[ "$size" -ne 4800 ]]; then
    printf 'expected 4800 bytes (40*40*3), got %s\n' "$size" >&2
    exit 1
fi
