#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

case "$case_id" in
  usage-exif-cli-machine-datetime)
    exif --machine-readable --tag=DateTime "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '2009:10:10 16:42:32'
    ;;
  usage-exif-cli-machine-datetime-original)
    exif --machine-readable --tag=DateTimeOriginal "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '2009:10:10 16:42:32'
    ;;
  usage-exif-cli-machine-model-value)
    exif --machine-readable --tag=Model "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Canon PowerShot S70'
    ;;
  usage-exif-cli-ifd-exif-exposure-time)
    exif --ifd=EXIF "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Exposure Time'
    ;;
  usage-exif-cli-ifd-exif-fnumber)
    exif --ifd=EXIF "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'F-Number'
    ;;
  usage-exif-cli-ifd-zero-make)
    exif --ifd=0 "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Manufacturer'
    validator_assert_contains "$tmpdir/out" 'Canon'
    ;;
  usage-exif-cli-list-pixel-dimensions)
    exif "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Pixel X Dimension'
    validator_assert_contains "$tmpdir/out" 'Pixel Y Dimension'
    ;;
  usage-exif-cli-list-color-space)
    exif "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Color Space'
    validator_assert_contains "$tmpdir/out" 'sRGB'
    ;;
  usage-exif-cli-xml-orientation-tag)
    exif --xml-output "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '<Orientation>Right-top</Orientation>'
    ;;
  usage-exif-cli-xml-focal-length)
    exif --xml-output "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '<Focal_Length>5.8 mm</Focal_Length>'
    ;;
  *)
    printf 'unknown libexif even-more usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
