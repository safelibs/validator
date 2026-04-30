#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-fire-image-frame-count
# @title: gifbuild dump frame count matches giftext
# @description: Counts the per-frame image headers gifbuild -d emits for fire.gif and asserts the count agrees with the number of Image # records giftext reports for the same animated input.
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
giftext "$gif" >"$tmpdir/text.txt"

build_frames=$(grep -cE '^image # [0-9]+$' "$tmpdir/dump.txt" || true)
text_frames=$(grep -cE '^Image #[0-9]+:' "$tmpdir/text.txt" || true)

(( build_frames > 1 )) || {
  printf 'expected multi-frame fixture, gifbuild reports %d frames\n' "$build_frames" >&2
  exit 1
}
if [[ "$build_frames" != "$text_frames" ]]; then
  printf 'frame count mismatch: gifbuild=%s giftext=%s\n' "$build_frames" "$text_frames" >&2
  exit 1
fi
