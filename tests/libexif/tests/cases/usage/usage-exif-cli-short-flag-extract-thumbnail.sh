#!/usr/bin/env bash
# @testcase: usage-exif-cli-short-flag-extract-thumbnail
# @title: exif -e -o short-flag form extracts the thumbnail
# @description: Invokes exif using the short-flag form (-e for --extract-thumbnail and -o for --output) instead of the long-flag form and verifies the client writes the same 4-byte thumbnail payload to the requested path with the canonical "Wrote file" diagnostic. Pins libexif's short-flag parity on Ubuntu 24.04 so dependent clients that prefer terse argv can rely on identical behavior.
# @timeout: 120
# @tags: usage, metadata, short-flag
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-short-flag-extract-thumbnail"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

short_out="$tmpdir/short.jpg"
long_out="$tmpdir/long.jpg"

exif -e -o "$short_out" "$img" >"$tmpdir/short.log"
exif --extract-thumbnail --output="$long_out" "$img" >"$tmpdir/long.log"

validator_assert_contains "$tmpdir/short.log" "Wrote file '$short_out'"
validator_assert_contains "$tmpdir/long.log" "Wrote file '$long_out'"

validator_require_file "$short_out"
validator_require_file "$long_out"

if ! cmp -s "$short_out" "$long_out"; then
  printf 'expected -e/-o and --extract-thumbnail/--output to write identical bytes\n' >&2
  od -An -tx1 "$short_out" >&2
  od -An -tx1 "$long_out" >&2
  exit 1
fi

short_size=$(stat -c '%s' "$short_out")
if (( short_size <= 0 )); then
  printf 'expected short-flag thumbnail to be non-empty, got %d bytes\n' "$short_size" >&2
  exit 1
fi
