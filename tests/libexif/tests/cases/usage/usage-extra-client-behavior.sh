#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

case "$case_id" in
  usage-exif-cli-ifd-zero)
    exif --ifd=0 "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Manufacturer'
    validator_assert_contains "$tmpdir/out" 'Canon'
    ;;
  usage-exif-cli-machine-model)
    exif --machine-readable --tag=Model "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Canon PowerShot S70'
    ;;
  usage-exif-cli-machine-make)
    exif --machine-readable --tag=Make "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Canon'
    ;;
  usage-exif-cli-exposure-time)
    exif --tag=ExposureTime "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Value:'
    ;;
  usage-exif-cli-fnumber)
    exif --tag=FNumber "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Value:'
    ;;
  usage-exif-cli-flash-tag)
    exif --tag=Flash "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Value:'
    ;;
  usage-exif-cli-white-balance-tag)
    exif --tag=WhiteBalance "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Value:'
    ;;
  usage-exif-cli-pixel-dimensions)
    exif --tag=PixelXDimension "$img" | tee "$tmpdir/x"
    exif --tag=PixelYDimension "$img" | tee "$tmpdir/y"
    validator_assert_contains "$tmpdir/x" 'Value:'
    validator_assert_contains "$tmpdir/y" 'Value:'
    ;;
  usage-exif-cli-xml-make)
    exif --xml-output "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '<Manufacturer>Canon</Manufacturer>'
    ;;
  usage-exif-cli-thumbnail-size)
    exif --extract-thumbnail --output="$tmpdir/thumb.jpg" "$img"
    validator_require_file "$tmpdir/thumb.jpg"
    test "$(wc -c <"$tmpdir/thumb.jpg")" -gt 0
    ;;
  *)
    printf 'unknown libexif extra usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
