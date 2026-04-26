#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

case "$case_id" in
  usage-exif-cli-machine-orientation)
    exif --machine-readable --tag=Orientation "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Right-top'
    ;;
  usage-exif-cli-machine-focal-length)
    exif --machine-readable --tag=FocalLength "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '5.8 mm'
    ;;
  usage-exif-cli-machine-color-space)
    exif --machine-readable --tag=ColorSpace "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'sRGB'
    ;;
  usage-exif-cli-tag-pixel-x-dimension)
    exif --tag=PixelXDimension "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '640'
    ;;
  usage-exif-cli-tag-pixel-y-dimension)
    exif --tag=PixelYDimension "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '480'
    ;;
  usage-exif-cli-ifd-zero-model)
    exif --ifd=0 "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Model'
    validator_assert_contains "$tmpdir/out" 'Canon PowerShot S70'
    ;;
  usage-exif-cli-ifd-zero-orientation)
    exif --ifd=0 "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Orientation'
    validator_assert_contains "$tmpdir/out" 'Right-top'
    ;;
  usage-exif-cli-list-orientation)
    exif "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Orientation'
    validator_assert_contains "$tmpdir/out" 'Right-top'
    ;;
  usage-exif-cli-list-focal-length)
    exif "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Focal Length'
    validator_assert_contains "$tmpdir/out" '5.8 mm'
    ;;
  usage-exif-cli-xml-model)
    exif --xml-output "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '<Model>Canon PowerShot S70</Model>'
    ;;
  *)
    printf 'unknown libexif additional usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
