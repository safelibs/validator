#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

case "$case_id" in
  usage-exif-cli-machine-x-resolution-batch11)
    exif --machine-readable --tag=XResolution "$img" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '180'
    ;;
  usage-exif-cli-machine-y-resolution-batch11)
    exif --machine-readable --tag=YResolution "$img" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '180'
    ;;
  usage-exif-cli-ifd-one-compression-batch11)
    exif --ifd=1 "$img" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Compression'
    ;;
  usage-exif-cli-ifd-one-resolution-unit-batch11)
    exif --ifd=1 "$img" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Resolution Unit'
    ;;
  usage-exif-cli-xml-exif-version-batch11)
    exif --xml-output "$img" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '<Exif_Version>'
    ;;
  usage-exif-cli-xml-flashpix-version-batch11)
    exif --xml-output "$img" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '<FlashPixVersion>'
    ;;
  usage-exif-cli-tag-ycbcr-positioning-batch11)
    exif --tag=YCbCrPositioning "$img" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Value:'
    ;;
  usage-exif-cli-machine-ycbcr-positioning-batch11)
    exif --machine-readable --tag=YCbCrPositioning "$img" >"$tmpdir/out"
    test "$(wc -c <"$tmpdir/out")" -gt 0
    ;;
  usage-exif-cli-show-mnote-byte-order-batch11)
    exif --show-mnote "$img" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Firmware Version'
    ;;
  usage-exif-cli-thumbnail-nonempty-batch11)
    exif --extract-thumbnail --output="$tmpdir/thumb.jpg" "$img"
    validator_require_file "$tmpdir/thumb.jpg"
    test "$(wc -c <"$tmpdir/thumb.jpg")" -gt 0
    ;;
  *)
    printf 'unknown libexif eleventh-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
