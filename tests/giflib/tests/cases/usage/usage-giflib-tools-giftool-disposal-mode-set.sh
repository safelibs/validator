#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-disposal-mode-set
# @title: giftool -x 2 sets disposal mode 2 on every fire.gif frame
# @description: Pipes fire.gif through giftool -x 2 to set the per-frame disposal mode to 2 (restore-to-background), captures giftext -e on the result, and verifies that every Disposal Mode line in the output reads "Disposal Mode: 2" with the count matching the frame count, exercising the previously uncovered -x flag.
# @timeout: 60
# @tags: usage, cli, giftool, disposal
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftool -x 2 <"$gif" >"$tmpdir/x2.gif"
file "$tmpdir/x2.gif" | grep -q 'GIF image data'

giftext -e "$tmpdir/x2.gif" >"$tmpdir/ext.txt"
giftext "$tmpdir/x2.gif" >"$tmpdir/info.txt"

frame_count=$(grep -cE '^Image #[0-9]+:' "$tmpdir/info.txt" || true)
if (( frame_count < 2 )); then
  printf 'expected multi-frame fire.gif, got %s frames\n' "$frame_count" >&2
  exit 1
fi

mode2_count=$(grep -cE '^[[:space:]]*Disposal Mode: 2$' "$tmpdir/ext.txt" || true)
if [[ "$mode2_count" != "$frame_count" ]]; then
  printf 'expected Disposal Mode: 2 on every frame: frames=%s mode2=%s\n' \
    "$frame_count" "$mode2_count" >&2
  grep -E 'Disposal Mode' "$tmpdir/ext.txt" >&2 || true
  exit 1
fi

# No other disposal mode should remain.
other=$(grep -E 'Disposal Mode:' "$tmpdir/ext.txt" | grep -vE 'Disposal Mode: 2$' | wc -l)
if (( other > 0 )); then
  printf 'unexpected non-2 disposal modes after -x 2:\n' >&2
  grep -E 'Disposal Mode:' "$tmpdir/ext.txt" | grep -vE 'Disposal Mode: 2$' >&2
  exit 1
fi

exit 0
