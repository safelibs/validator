#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-format-grid-frame-count
# @title: giftool -f emits exactly one frame line for the single-image gifgrid fixture
# @description: Runs giftool -f '%n %wx%h\n' against gifgrid.gif and asserts the listing has exactly one row whose frame index is 1 and whose width-by-height matches the screen size giftext extracts, anchoring the %n directive on a non-animated fixture.
# @timeout: 60
# @tags: usage, cli, giftool, format
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"

giftext "$gif" >"$tmpdir/text.txt"
expected_size=$(sed -n 's/.*Screen Size - Width = \([0-9]*\), Height = \([0-9]*\)\..*/\1x\2/p' "$tmpdir/text.txt" | head -n1)
[[ -n "$expected_size" ]] || {
  printf 'could not parse screen size from giftext output\n' >&2
  cat "$tmpdir/text.txt" >&2
  exit 1
}

giftool -f '%n %wx%h\n' <"$gif" >"$tmpdir/frames.txt"
listed=$(wc -l <"$tmpdir/frames.txt")
[[ "$listed" -eq 1 ]] || {
  printf 'expected exactly 1 frame line for gifgrid, got %s\n' "$listed" >&2
  cat "$tmpdir/frames.txt" >&2
  exit 1
}

read -r idx dims <"$tmpdir/frames.txt"
[[ "$idx" == "1" ]] || {
  printf 'expected first frame index 1, got %s\n' "$idx" >&2
  exit 1
}
[[ "$dims" == "$expected_size" ]] || {
  printf 'frame dimensions %s do not match screen size %s\n' "$dims" "$expected_size" >&2
  exit 1
}
