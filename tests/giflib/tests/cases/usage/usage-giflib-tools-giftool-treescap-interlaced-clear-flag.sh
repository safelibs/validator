#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-treescap-interlaced-clear-flag
# @title: giftool -i 0 clears interlace on an already-interlaced fixture
# @description: Confirms the treescap-interlaced.gif fixture is in fact interlaced via giftext, runs giftool -i 0 to clear the per-image interlace flag, and verifies the resulting GIF parses without the Image is Interlaced marker while preserving its screen size, exercising the inverse of giftool -i 1.
# @timeout: 60
# @tags: usage, cli, giftool, interlace
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap-interlaced.gif"
validator_require_file "$gif"

# Sanity: source must already be interlaced or the assertion below is vacuous.
giftext "$gif" >"$tmpdir/before.txt"
validator_assert_contains "$tmpdir/before.txt" 'Image is Interlaced'

# Capture the source screen size to confirm -i 0 is a flag-only transform.
orig_size_line=$(grep -E 'Screen[[:space:]]+Size' "$tmpdir/before.txt" | head -n 1)
[[ -n "$orig_size_line" ]] || {
  printf 'no Screen Size record on source fixture\n' >&2
  exit 1
}

giftool -i 0 <"$gif" >"$tmpdir/cleared.gif"
file "$tmpdir/cleared.gif" | grep -q 'GIF image data'

giftext "$tmpdir/cleared.gif" >"$tmpdir/after.txt"

# The interlace marker must be gone.
if grep -q 'Image is Interlaced' "$tmpdir/after.txt"; then
  printf 'giftool -i 0 did not clear the interlace flag\n' >&2
  sed -n '1,40p' "$tmpdir/after.txt" >&2
  exit 1
fi

# Screen size must be preserved across the flag-only transform.
new_size_line=$(grep -E 'Screen[[:space:]]+Size' "$tmpdir/after.txt" | head -n 1)
[[ "$orig_size_line" == "$new_size_line" ]] || {
  printf 'screen size changed: orig=%q new=%q\n' "$orig_size_line" "$new_size_line" >&2
  exit 1
}
