#!/usr/bin/env bash
# @testcase: usage-exif-cli-remove-datetime-ifd-zero
# @title: exif --remove --tag=DateTime --ifd=0 strips the top-level timestamp
# @description: Copies the canon JPEG fixture to a tmpdir and removes the top-level DateTime tag from IFD 0 with exif --remove, then verifies the rewritten file no longer reports DateTime via --tag=DateTime, that IFD 0 entry count drops from 9 to 8 in the --debug trace, and that the unrelated Model tag remains intact and equal to the original readout.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-remove-datetime-ifd-zero"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

# Baseline: DateTime is present and IFD 0 reports 9 entries.
exif --tag=DateTime "$img" >"$tmpdir/before.tag"
validator_assert_contains "$tmpdir/before.tag" '2009:10:10 16:42:32'
exif --debug "$img" >"$tmpdir/before.debug" 2>&1
validator_assert_contains "$tmpdir/before.debug" 'ExifData: Loading 9 entries...'

# Capture the Model readout for a post-strip cross-check.
exif --tag=Model "$img" >"$tmpdir/before.model"

# Strip --tag=DateTime --ifd=0 to a new file.
cp "$img" "$tmpdir/source.jpg"
exif --remove --tag=DateTime --ifd=0 \
  --output="$tmpdir/stripped.jpg" "$tmpdir/source.jpg" >"$tmpdir/write.log"
validator_assert_contains "$tmpdir/write.log" 'Wrote file'
validator_require_file "$tmpdir/stripped.jpg"

# DateTime lookup on the stripped file must report the tag is gone.
exif --tag=DateTime "$tmpdir/stripped.jpg" \
  >"$tmpdir/after.tag" 2>&1 || true
validator_assert_contains "$tmpdir/after.tag" "does not contain tag 'DateTime'"

# The 2009:10:10 16:42:32 timestamp from the top-level DateTime tag
# must be gone from --tag=DateTime output (DateTimeOriginal in EXIF IFD
# may still be probed separately; we are checking only the symbolic
# DateTime tag in IFD 0).
if grep -Fq '2009:10:10 16:42:32' "$tmpdir/after.tag"; then
  printf 'expected DateTime timestamp gone after --remove, still present\n' >&2
  cat "$tmpdir/after.tag" >&2
  exit 1
fi

# IFD 0 entry count must drop from 9 to 8 in the --debug trace.
exif --debug "$tmpdir/stripped.jpg" >"$tmpdir/after.debug" 2>&1
validator_assert_contains "$tmpdir/after.debug" 'ExifData: Loading 8 entries...'

# The Model tag must remain unchanged across the strip.
exif --tag=Model "$tmpdir/stripped.jpg" >"$tmpdir/after.model"
if ! cmp -s "$tmpdir/before.model" "$tmpdir/after.model"; then
  printf 'Model tag readout changed after --remove --tag=DateTime\n' >&2
  diff -u "$tmpdir/before.model" "$tmpdir/after.model" >&2 || true
  exit 1
fi
