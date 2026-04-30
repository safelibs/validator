#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-treescap-interlaced-dump-counts
# @title: gifbuild dump on treescap-interlaced has matching image and screen records
# @description: Dumps the treescap-interlaced.gif fixture with gifbuild -d and asserts the dump contains exactly one screen-width record, exactly one image header line, an image with a non-zero bits-per-pixel record, and concludes with the trailer keyword, exercising gifbuild's structural rendering of a single-frame interlaced fixture.
# @timeout: 60
# @tags: usage, cli, gifbuild, interlace
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap-interlaced.gif"
validator_require_file "$gif"

gifbuild -d "$gif" >"$tmpdir/dump.txt"

# Exactly one logical-screen descriptor.
sw_count=$(grep -cE '^screen width [0-9]+$' "$tmpdir/dump.txt" || true)
[[ "$sw_count" -eq 1 ]] || {
  printf 'expected exactly 1 "screen width" line, got %d\n' "$sw_count" >&2
  exit 1
}
sh_count=$(grep -cE '^[[:space:]]*screen height [0-9]+$' "$tmpdir/dump.txt" || true)
[[ "$sh_count" -eq 1 ]] || {
  printf 'expected exactly 1 "screen height" line, got %d\n' "$sh_count" >&2
  exit 1
}

# treescap-interlaced is single-frame.
img_count=$(grep -cE '^image # [0-9]+$' "$tmpdir/dump.txt" || true)
[[ "$img_count" -eq 1 ]] || {
  printf 'expected exactly 1 image header, got %d\n' "$img_count" >&2
  sed -n '1,40p' "$tmpdir/dump.txt" >&2
  exit 1
}

# Image dimension record must be present and non-zero (gifbuild emits
# "image bits W by H" giving the image's pixel dimensions).
if ! grep -qE '^[[:space:]]*image bits [1-9][0-9]* by [1-9][0-9]*$' "$tmpdir/dump.txt"; then
  printf 'no positive image bits dimension record\n' >&2
  sed -n '1,40p' "$tmpdir/dump.txt" >&2
  exit 1
fi

# The interlaced flag must be present for this single-frame interlaced fixture.
if ! grep -qE '^[[:space:]]*image interlaced$' "$tmpdir/dump.txt"; then
  printf 'no image interlaced record\n' >&2
  sed -n '1,40p' "$tmpdir/dump.txt" >&2
  exit 1
fi
