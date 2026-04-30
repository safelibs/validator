#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-fire-gcb-frame-equal
# @title: gifbuild dump emits exactly one graphics control per fire frame
# @description: Dumps the animated fire.gif with gifbuild -d and asserts the count of "graphics control" extension blocks is exactly equal to the count of "image # N" headers, cross-verifying the frame count against giftool -f, so we are confirming a strict 1:1 pairing rather than just the presence of GCBs.
# @timeout: 60
# @tags: usage, cli, gifbuild, animation
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

gifbuild -d "$gif" >"$tmpdir/dump.txt"

images=$(grep -cE '^image # [0-9]+$' "$tmpdir/dump.txt" || true)
gcbs=$(grep -c '^graphics control$'   "$tmpdir/dump.txt" || true)

(( images >= 5 )) || {
  printf 'expected animated fixture, got %d image headers\n' "$images" >&2
  exit 1
}
if [[ "$images" != "$gcbs" ]]; then
  printf 'frame/GCB parity violated: images=%s gcbs=%s\n' "$images" "$gcbs" >&2
  sed -n '1,40p' "$tmpdir/dump.txt" >&2
  exit 1
fi

# Cross-check the frame count against giftool -f.
giftool -f '%n\n' <"$gif" >"$tmpdir/frames.txt"
listed=$(wc -l <"$tmpdir/frames.txt")
if [[ "$listed" != "$images" ]]; then
  printf 'frame count mismatch: gifbuild=%s giftool=%s\n' "$images" "$listed" >&2
  exit 1
fi
