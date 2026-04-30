#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftool-position-format-combo
# @title: giftool -p position survives a follow-up giftool -f format extraction
# @description: Pipes treescap.gif through giftool -p 6,9 to set the image origin, then through a second giftool -f invocation that emits a custom format line per frame, and confirms the format pass enumerates the expected number of frames while gifbuild dumps the new image left 6 and image top 9 coordinates on the positioned stream.
# @timeout: 60
# @tags: usage, cli, giftool, pipeline
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

# Anchor expected frame count from gifbuild dump of the original fixture.
gifbuild -d "$gif" >"$tmpdir/orig-dump.txt"
expected_frames=$(grep -cE '^image # [0-9]+$' "$tmpdir/orig-dump.txt" || true)
(( expected_frames >= 1 )) || {
  printf 'expected at least one frame, got %d\n' "$expected_frames" >&2
  exit 1
}

# Stage 1: rewrite the image origin.
giftool -p 6,9 <"$gif" >"$tmpdir/positioned.gif"
file "$tmpdir/positioned.gif" | grep -q 'GIF image data'

# Verify the new origin is recorded by gifbuild on the positioned stream.
gifbuild -d "$tmpdir/positioned.gif" >"$tmpdir/pos-dump.txt"
if ! grep -qE '^[[:space:]]*image left 6$' "$tmpdir/pos-dump.txt"; then
  printf 'expected "image left 6" line in positioned dump\n' >&2
  sed -n '1,40p' "$tmpdir/pos-dump.txt" >&2
  exit 1
fi
if ! grep -qE '^[[:space:]]*image top 9$' "$tmpdir/pos-dump.txt"; then
  printf 'expected "image top 9" line in positioned dump\n' >&2
  sed -n '1,40p' "$tmpdir/pos-dump.txt" >&2
  exit 1
fi

# Stage 2: enumerate frames on the positioned stream via giftool -f.
giftool -f 'frame=%n size=%wx%h\n' <"$tmpdir/positioned.gif" >"$tmpdir/listing.txt"
listed=$(wc -l <"$tmpdir/listing.txt")
if [[ "$listed" != "$expected_frames" ]]; then
  printf 'expected %s frames in -f listing, got %s\n' "$expected_frames" "$listed" >&2
  sed -n '1,5p' "$tmpdir/listing.txt" >&2
  exit 1
fi

# The very first listed frame must carry the expected format prefix.
first=$(head -n 1 "$tmpdir/listing.txt")
if [[ "$first" != frame=1\ size=*x* ]]; then
  printf 'unexpected first -f line: %q\n' "$first" >&2
  exit 1
fi
