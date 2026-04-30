#!/usr/bin/env bash
# @testcase: usage-exif-cli-set-value-datetime-original-readback
# @title: exif --set-value rewrites DateTimeOriginal
# @description: Uses exif --set-value with --ifd=EXIF to overwrite DateTimeOriginal on a copy of the canon fixture and confirms the new timestamp is reported on readback.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

cp "$img" "$tmpdir/source.jpg"
exif --ifd=EXIF --tag=DateTimeOriginal --set-value='2030:12:31 23:59:59' \
  --output="$tmpdir/edited.jpg" "$tmpdir/source.jpg" >"$tmpdir/write.log"
validator_assert_contains "$tmpdir/write.log" "Wrote file"
validator_require_file "$tmpdir/edited.jpg"

# Confirm rewrite is visible on the new file
exif --tag=DateTimeOriginal "$tmpdir/edited.jpg" >"$tmpdir/edited.out"
validator_assert_contains "$tmpdir/edited.out" "Tag: 0x9003 ('DateTimeOriginal')"
validator_assert_contains "$tmpdir/edited.out" "Value: 2030:12:31 23:59:59"

# Original fixture should still report its baked-in capture timestamp
exif --tag=DateTimeOriginal "$img" >"$tmpdir/original.out"
validator_assert_contains "$tmpdir/original.out" "Value: 2009:10:10 16:42:32"
