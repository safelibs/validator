#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gif2rgb-fire-bytes-frame-multiple
# @title: gif2rgb fire output is an exact integer number of frame bytes
# @description: Decodes the multi-frame fire.gif with gif2rgb -1 into a single RGB stream and verifies the byte count is exactly width*height*3 multiplied by an integer between 1 and the frame count reported by gifbuild, ensuring gif2rgb is emitting whole frames worth of pixel data with no slack.
# @timeout: 60
# @tags: usage, cli, gif2rgb, animation
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

# Read the screen dimensions from giftext.
giftext "$gif" >"$tmpdir/info.txt"
w=$(grep -Eo 'Width = [0-9]+' "$tmpdir/info.txt" | head -n 1 | awk '{print $3}')
h=$(grep -Eo 'Height = [0-9]+' "$tmpdir/info.txt" | head -n 1 | awk '{print $3}')
[[ "$w" =~ ^[1-9][0-9]*$ ]] || { printf 'bad width: %q\n' "$w" >&2; exit 1; }
[[ "$h" =~ ^[1-9][0-9]*$ ]] || { printf 'bad height: %q\n' "$h" >&2; exit 1; }

# Frame count from gifbuild; bound the reasonable RGB output between 1 and N frames.
gifbuild -d "$gif" >"$tmpdir/dump.txt"
frames=$(grep -cE '^image # [0-9]+$' "$tmpdir/dump.txt" || true)
(( frames >= 2 )) || {
  printf 'expected fire.gif to be multi-frame, got %d\n' "$frames" >&2
  exit 1
}

gif2rgb -1 -o "$tmpdir/out.rgb" "$gif"
bytes=$(wc -c <"$tmpdir/out.rgb")
frame_bytes=$(( w * h * 3 ))
(( frame_bytes > 0 )) || { printf 'frame_bytes computed as 0\n' >&2; exit 1; }

# bytes must be a positive integer multiple of frame_bytes, and that multiple
# must lie in [1, frames].
if (( bytes % frame_bytes != 0 )); then
  printf 'gif2rgb output %d not a multiple of %d (=%d*%d*3)\n' \
    "$bytes" "$frame_bytes" "$w" "$h" >&2
  exit 1
fi
multiple=$(( bytes / frame_bytes ))
if (( multiple < 1 )) || (( multiple > frames )); then
  printf 'multiple %d outside [1, %d]\n' "$multiple" "$frames" >&2
  exit 1
fi
