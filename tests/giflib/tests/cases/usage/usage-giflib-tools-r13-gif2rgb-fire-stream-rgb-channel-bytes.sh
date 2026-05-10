#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r13-gif2rgb-fire-stream-rgb-channel-bytes
# @title: gif2rgb -1 fire.gif emits 3 * w * h bytes for the first frame
# @description: Decodes fire.gif via gif2rgb -1 into a stream RGB file and asserts the byte count equals 3 * first_frame_width * first_frame_height, exercising the RGB-per-pixel stream emission. (gif2rgb -1 emits a single frame's pixels regardless of frame count on giflib 5.2.2.)
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

# First-frame ImageDesc geometry via giftool format cookies %w (width) and %h
# (height); gif2rgb -1 on giflib 5.2.2 emits exactly one frame's RGB pixels.
giftool -f '%w %h\n' <"$gif" >"$tmpdir/wh.txt"
[[ -s "$tmpdir/wh.txt" ]]

read -r w h <"$tmpdir/wh.txt"
expected=$((3 * w * h))
[[ "$expected" -gt 0 ]]

if [[ "$bytes" -ne "$expected" ]]; then
    printf 'gif2rgb -1 stream %s bytes != 3 * %s * %s = %s\n' \
        "$bytes" "$w" "$h" "$expected" >&2
    exit 1
fi
