#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload=${1:?missing exif CLI workload}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

case "$workload" in
  usage-exif-cli-tag-flash-value)
    exif --tag=Flash "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Value:'
    ;;
  usage-exif-cli-tag-exposure-time-value)
    exif --tag=ExposureTime "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Value:'
    ;;
  usage-exif-cli-tag-fnumber-value)
    exif --tag=FNumber "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Value:'
    ;;
  usage-exif-cli-tag-resolution-unit-value)
    exif --tag=ResolutionUnit "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Value:'
    ;;
  usage-exif-cli-tag-exif-version-value)
    exif --tag=ExifVersion "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Value:'
    ;;
  usage-exif-cli-tag-flashpix-version-value)
    exif --tag=FlashPixVersion "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Value:'
    ;;
  usage-exif-cli-machine-readable-model-line)
    exif --machine-readable "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Model'
    ;;
  usage-exif-cli-machine-readable-date-and-time-line)
    exif --machine-readable "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Date and Time'
    ;;
  usage-exif-cli-xml-manufacturer-element)
    exif --xml-output "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '<Manufacturer>Canon</Manufacturer>'
    ;;
  usage-exif-cli-xml-date-and-time-element)
    exif --xml-output "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '<Date_and_Time>'
    ;;
  *)
    printf 'unknown exif expanded usage case: %s\n' "$workload" >&2
    exit 2
    ;;
esac
