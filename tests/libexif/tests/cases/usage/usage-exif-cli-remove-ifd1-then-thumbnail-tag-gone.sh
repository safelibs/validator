#!/usr/bin/env bash
# @testcase: usage-exif-cli-remove-ifd1-then-thumbnail-tag-gone
# @title: exif --remove --ifd=1 invalidates thumbnail Compression value
# @description: Removes IFD 1 from a copy of the canon fixture using exif --remove --ifd=1, then re-reads --tag=Compression --ifd=1 against the rewritten file and confirms the Compression entry value collapses to the libexif Internal error (unknown value 0) marker rather than the original JPEG compression label, while IFD 0 Make remains Canon and the original fixture still reports JPEG compression.
# @timeout: 180
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-remove-ifd1-then-thumbnail-tag-gone"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

# Baseline: original fixture has JPEG compression for IFD 1
exif --tag=Compression --ifd=1 "$img" >"$tmpdir/before.out"
validator_assert_contains "$tmpdir/before.out" "Tag: 0x103 ('Compression')"
validator_assert_contains "$tmpdir/before.out" 'Value: JPEG compression'

# Remove IFD 1
cp "$img" "$tmpdir/source.jpg"
exif --remove --ifd=1 --output="$tmpdir/stripped.jpg" "$tmpdir/source.jpg" >"$tmpdir/strip.log"
validator_assert_contains "$tmpdir/strip.log" 'Wrote file'
validator_require_file "$tmpdir/stripped.jpg"

# After IFD-1 removal, Compression value should be the libexif "Internal error" marker
exif --tag=Compression --ifd=1 "$tmpdir/stripped.jpg" >"$tmpdir/after.out"
validator_assert_contains "$tmpdir/after.out" "Tag: 0x103 ('Compression')"
validator_assert_contains "$tmpdir/after.out" 'Value: Internal error (unknown value 0)'

# Original JPEG compression label must NOT survive
if grep -Fq -- 'JPEG compression' "$tmpdir/after.out"; then
  printf 'IFD 1 Compression unexpectedly still reads JPEG compression after --remove --ifd=1\n' >&2
  cat "$tmpdir/after.out" >&2
  exit 1
fi

# IFD 0 Make remains intact
exif --tag=Make --ifd=0 "$tmpdir/stripped.jpg" >"$tmpdir/make.out"
validator_assert_contains "$tmpdir/make.out" 'Value: Canon'

# Original fixture must remain untouched
exif --tag=Compression --ifd=1 "$img" >"$tmpdir/original-after.out"
validator_assert_contains "$tmpdir/original-after.out" 'Value: JPEG compression'
