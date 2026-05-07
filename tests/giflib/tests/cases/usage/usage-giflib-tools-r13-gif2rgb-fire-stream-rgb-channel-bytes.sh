#!/usr/bin/env bash
# @testcase: usage-giflib-tools-r13-gif2rgb-fire-stream-rgb-channel-bytes
# @title: gif2rgb -1 fire.gif stream byte count equals 3 x screen pixels x frame count
# @description: Decodes fire.gif via gif2rgb -1 into a stream RGB file, then compares the byte count to 3 * screen_w * screen_h * frame_count derived from giftool -f and asserts equality, exercising the stream-mode multi-frame output.
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

# Derive expected size from giftool format cookies.
giftool -f '%s\n' <"$gif" >"$tmpdir/screen.txt"
giftool -f '%n\n' <"$gif" >"$tmpdir/n.txt"

read -r screen_w screen_h <<<"$(head -n 1 "$tmpdir/screen.txt" | tr ',' ' ')"
frames=$(wc -l <"$tmpdir/n.txt")

[[ "$screen_w" -gt 0 && "$screen_h" -gt 0 && "$frames" -ge 1 ]]

expected=$((3 * screen_w * screen_h * frames))
if [[ "$bytes" -ne "$expected" ]]; then
    printf 'gif2rgb -1 stream %s bytes != 3*%s*%s*%s = %s\n' \
        "$bytes" "$screen_w" "$screen_h" "$frames" "$expected" >&2
    exit 1
fi
