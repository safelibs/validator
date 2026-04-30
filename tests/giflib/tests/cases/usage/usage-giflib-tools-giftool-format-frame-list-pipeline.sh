#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-format-frame-list-pipeline
# @title: giftool -f lists every frame after a giftool -d transform
# @description: Pipes fire.gif through giftool -d 75, then asks a second giftool -f invocation to emit one line per frame with index and dimensions, and confirms the post-transform stream still enumerates every animated frame and that gifbuild reports the new delay on those frames.
# @timeout: 60
# @tags: usage, cli, giftool, pipeline, animation
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

# Expected frame count, anchored to the original fixture.
gifbuild -d "$gif" >"$tmpdir/orig-dump.txt"
orig_frames=$(grep -cE '^image # [0-9]+$' "$tmpdir/orig-dump.txt" || true)
(( orig_frames >= 2 )) || {
  printf 'expected fire.gif to be multi-frame, got %d\n' "$orig_frames" >&2
  exit 1
}

# Stage 1: rewrite the per-frame delay.
giftool -d 75 <"$gif" >"$tmpdir/delayed.gif"
file "$tmpdir/delayed.gif" | grep -q 'GIF image data'

# Stage 2: list the frames in the post-transform stream.
giftool -f '%n %wx%h\n' <"$tmpdir/delayed.gif" >"$tmpdir/frames.txt"
listed=$(wc -l <"$tmpdir/frames.txt")
if [[ "$listed" != "$orig_frames" ]]; then
  printf 'expected %s frames after pipeline, got %s\n' "$orig_frames" "$listed" >&2
  sed -n '1,5p' "$tmpdir/frames.txt" >&2
  exit 1
fi

# Frame indices in the listing must start at 1 and end at orig_frames.
first=$(head -n 1 "$tmpdir/frames.txt" | awk '{print $1}')
last=$(tail -n 1 "$tmpdir/frames.txt"  | awk '{print $1}')
[[ "$first" == "1" ]] || { printf 'expected first frame index 1, got %s\n' "$first" >&2; exit 1; }
[[ "$last" == "$orig_frames" ]] || {
  printf 'expected last frame index %s, got %s\n' "$orig_frames" "$last" >&2
  exit 1
}

# The new delay must show up at least once in the gifbuild dump of the result.
gifbuild -d "$tmpdir/delayed.gif" >"$tmpdir/dump.txt"
if ! grep -qE '^[[:space:]]+delay 75$' "$tmpdir/dump.txt"; then
  printf 'expected at least one "delay 75" line in post-pipeline dump\n' >&2
  exit 1
fi
