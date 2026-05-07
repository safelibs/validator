#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r14-gif2rgb-fire-frames-times-pixels-times-three
# @title: gif2rgb -1 fire stream byte count is integer multiple of frame_bytes within [1, frames]
# @description: Decodes fire.gif via gif2rgb -1 and asserts the RGB stream byte count divides cleanly by frame_bytes (Wxhx3) using the screen dimensions reported by giftext, and the resulting multiple is in the closed interval [1, frames] where frames is reported by giftool -f '%n\n', exercising the full-frame emission contract on a multi-frame fixture.
# @timeout: 60
# @tags: usage, cli, gif2rgb, math
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

frames=$(giftool -f '%n\n' <"$gif" | wc -l)
[[ "$frames" -ge 2 ]]

giftext "$gif" >"$tmpdir/info.txt"
size_line=$(grep -E 'Screen Size - Width = [0-9]+, Height = [0-9]+' "$tmpdir/info.txt" | head -n1)
w=$(printf '%s' "$size_line" | sed -n 's/.*Width = \([0-9]*\).*/\1/p')
h=$(printf '%s' "$size_line" | sed -n 's/.*Height = \([0-9]*\).*/\1/p')
(( w > 0 && h > 0 ))

gif2rgb -1 -o "$tmpdir/out.rgb" "$gif"
bytes=$(stat -c '%s' "$tmpdir/out.rgb")
fb=$((w * h * 3))

(( bytes % fb == 0 )) || {
    printf 'rgb bytes=%s not a multiple of frame_bytes=%s\n' "$bytes" "$fb" >&2
    exit 1
}

mult=$((bytes / fb))
(( mult >= 1 && mult <= frames )) || {
    printf 'multiple %s outside [1, %s]\n' "$mult" "$frames" >&2
    exit 1
}
