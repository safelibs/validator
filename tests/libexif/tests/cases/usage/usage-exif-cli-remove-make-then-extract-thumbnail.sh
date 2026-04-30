#!/usr/bin/env bash
# @testcase: usage-exif-cli-remove-make-then-extract-thumbnail
# @title: exif --remove Make leaves the embedded thumbnail intact
# @description: Strips the IFD 0 Make tag from a copy of the canon fixture with exif --remove --tag=Make, then runs --extract-thumbnail against the rewritten file and verifies the thumbnail still extracts byte-for-byte identically to the thumbnail extracted from the untouched original, confirming Make removal and thumbnail extraction are independent.
# @timeout: 180
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-remove-make-then-extract-thumbnail"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

# Baseline thumbnail from the untouched original
exif --extract-thumbnail --output="$tmpdir/baseline.thumb" "$img" >"$tmpdir/baseline.log"
validator_assert_contains "$tmpdir/baseline.log" 'Wrote file'
validator_require_file "$tmpdir/baseline.thumb"

# Remove Make on a copy
cp "$img" "$tmpdir/source.jpg"
exif --remove --tag=Make --ifd=0 --output="$tmpdir/stripped.jpg" "$tmpdir/source.jpg" >"$tmpdir/strip.log"
validator_assert_contains "$tmpdir/strip.log" 'Wrote file'
validator_require_file "$tmpdir/stripped.jpg"

# Make must be gone in the stripped copy
exif --tag=Make "$tmpdir/stripped.jpg" >"$tmpdir/make.out" 2>&1 || true
validator_assert_contains "$tmpdir/make.out" "does not contain tag 'Make'"

# Thumbnail must still extract from the stripped copy
exif --extract-thumbnail --output="$tmpdir/post.thumb" "$tmpdir/stripped.jpg" >"$tmpdir/post.log"
validator_assert_contains "$tmpdir/post.log" 'Wrote file'
validator_require_file "$tmpdir/post.thumb"

# And the extracted bytes must be identical to the baseline
if ! cmp -s "$tmpdir/baseline.thumb" "$tmpdir/post.thumb"; then
  printf 'thumbnail bytes diverged after Make removal\n' >&2
  cmp "$tmpdir/baseline.thumb" "$tmpdir/post.thumb" >&2 || true
  exit 1
fi

# Model must still be present and intact in the stripped copy
exif --tag=Model "$tmpdir/stripped.jpg" >"$tmpdir/model.out"
validator_assert_contains "$tmpdir/model.out" 'Value: Canon PowerShot S70'
