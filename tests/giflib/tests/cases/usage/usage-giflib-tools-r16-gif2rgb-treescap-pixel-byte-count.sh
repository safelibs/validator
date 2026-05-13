#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r16-gif2rgb-treescap-pixel-byte-count
# @title: gif2rgb -1 treescap.gif emits exactly width*height*3 bytes per frame
# @description: Decodes treescap.gif via gif2rgb -1, derives width and height from giftext, and asserts the total RGB byte count is a positive integer multiple of width*height*3 with the multiple equal to the frame count reported by giftool -f '%n\n', exercising the full-frame byte-count contract on a non-interlaced fixture.
# @timeout: 60
# @tags: usage, cli, gif2rgb, bytes
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

giftext "$gif" >"$tmpdir/info.txt"
size_line=$(grep -E 'Screen Size - Width = [0-9]+, Height = [0-9]+' "$tmpdir/info.txt" | head -n1)
w=$(printf '%s' "$size_line" | sed -n 's/.*Width = \([0-9]*\).*/\1/p')
h=$(printf '%s' "$size_line" | sed -n 's/.*Height = \([0-9]*\).*/\1/p')
(( w > 0 && h > 0 ))

gif2rgb -1 -o "$tmpdir/out.rgb" "$gif"
bytes=$(stat -c '%s' "$tmpdir/out.rgb")
frame=$((w * h * 3))
(( bytes > 0 ))
(( bytes % frame == 0 )) || {
    printf 'bytes=%s not divisible by frame=%s\n' "$bytes" "$frame" >&2
    exit 1
}

multiple=$((bytes / frame))
nframes=$(giftool -f '%n\n' <"$gif" | wc -l)
(( multiple == nframes )) || {
    printf 'multiple=%s frames=%s\n' "$multiple" "$nframes" >&2
    exit 1
}
