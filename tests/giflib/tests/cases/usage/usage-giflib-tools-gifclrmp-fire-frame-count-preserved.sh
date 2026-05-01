#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifclrmp-fire-frame-count-preserved
# @title: gifclrmp gamma transform preserves fire.gif frame count
# @description: Applies a gamma colormap transform via gifclrmp -g 1.5 to the multi-frame fire.gif fixture, then counts the image records emitted by gifbuild -d on the transformed stream and asserts the count matches the source animation, ensuring the colormap rewrite leaves the frame structure intact.
# @timeout: 60
# @tags: usage, cli, gifclrmp, animation
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

orig_frames=$(gifbuild -d "$gif" | grep -cE '^image # [0-9]+$' || true)
(( orig_frames >= 2 )) || {
  printf 'expected fire.gif to be multi-frame, got %d\n' "$orig_frames" >&2
  exit 1
}

gifclrmp -g 1.5 "$gif" >"$tmpdir/gamma.gif"
file "$tmpdir/gamma.gif" | grep -q 'GIF image data'

new_frames=$(gifbuild -d "$tmpdir/gamma.gif" | grep -cE '^image # [0-9]+$' || true)
if [[ "$new_frames" != "$orig_frames" ]]; then
  printf 'gifclrmp -g 1.5 changed frame count: orig=%s new=%s\n' "$orig_frames" "$new_frames" >&2
  exit 1
fi
