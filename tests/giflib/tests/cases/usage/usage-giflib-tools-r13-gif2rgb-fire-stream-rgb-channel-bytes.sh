#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r13-gif2rgb-fire-stream-rgb-channel-bytes
# @title: gif2rgb -1 fire.gif stream byte count equals sum of 3 * w * h per frame
# @description: Decodes fire.gif via gif2rgb -1 into a stream RGB file, then sums 3 * frame_width * frame_height across frames using giftool -f '%w %h' (per-frame ImageDesc geometry, not screen geometry — gif2rgb stream mode emits each ImageDesc back-to-back) and asserts the byte count equals that sum.
# @timeout: 60
# @tags: usage, cli, gif2rgb, stream
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

gif2rgb -1 -o "$tmpdir/fire.rgb" "$gif"
[[ -s "$tmpdir/fire.rgb" ]]

bytes=$(wc -c <"$tmpdir/fire.rgb")

# Per-frame ImageDesc geometry via giftool format cookies %w (width) and %h (height).
giftool -f '%w %h\n' <"$gif" >"$tmpdir/wh.txt"
[[ -s "$tmpdir/wh.txt" ]]

expected=$(awk '{ s += 3 * $1 * $2 } END { print s }' "$tmpdir/wh.txt")
[[ -n "$expected" && "$expected" -gt 0 ]]

if [[ "$bytes" -ne "$expected" ]]; then
    printf 'gif2rgb -1 stream %s bytes != sum(3*w*h) = %s\n' "$bytes" "$expected" >&2
    sed -n '1,16p' "$tmpdir/wh.txt" >&2
    exit 1
fi
