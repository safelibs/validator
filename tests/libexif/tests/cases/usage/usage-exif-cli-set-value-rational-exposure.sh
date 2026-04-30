#!/usr/bin/env bash
# @testcase: usage-exif-cli-set-value-rational-exposure
# @title: exif --set-value rewrites rational ExposureTime
# @description: Uses exif --set-value with --ifd=EXIF to overwrite the rational ExposureTime tag using two-component numerator/denominator input on a copy of the canon fixture and verifies the rewritten JPEG reports the new 1/250 sec value while the original remains 1 sec.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-set-value-rational-exposure"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

cp "$img" "$tmpdir/source.jpg"
exif --ifd=EXIF --tag=ExposureTime --set-value='1 250' \
  --output="$tmpdir/edited.jpg" "$tmpdir/source.jpg" >"$tmpdir/write.log"
validator_assert_contains "$tmpdir/write.log" 'Wrote file'
validator_require_file "$tmpdir/edited.jpg"

# Original fixture must remain at 1 sec
exif --tag=ExposureTime "$img" >"$tmpdir/original.out"
validator_assert_contains "$tmpdir/original.out" 'Value: 1 sec.'

# Rewritten copy reports the new rational
exif --tag=ExposureTime "$tmpdir/edited.jpg" >"$tmpdir/edited.out"
validator_assert_contains "$tmpdir/edited.out" "Format: 5 ('Rational')"
validator_assert_contains "$tmpdir/edited.out" 'Value: 1/250 sec.'
