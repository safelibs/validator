#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

case "$case_id" in
  usage-exif-cli-machine-pixel-x-dimension)
    exif --machine-readable --tag=PixelXDimension "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '640'
    ;;
  usage-exif-cli-machine-pixel-y-dimension)
    exif --machine-readable --tag=PixelYDimension "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '480'
    ;;
  usage-exif-cli-machine-resolution-unit)
    exif --machine-readable --tag=ResolutionUnit "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Inch'
    ;;
  usage-exif-cli-machine-exif-version)
    exif --machine-readable --tag=ExifVersion "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Exif Version 2.2'
    ;;
  usage-exif-cli-machine-flashpix-version)
    exif --machine-readable --tag=FlashPixVersion "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'FlashPix Version 1.0'
    ;;
  usage-exif-cli-machine-related-image-width)
    exif --machine-readable --tag=RelatedImageWidth "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '640'
    ;;
  usage-exif-cli-machine-related-image-length)
    exif --machine-readable --tag=RelatedImageLength "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '480'
    ;;
  usage-exif-cli-machine-metering-mode)
    exif --machine-readable --tag=MeteringMode "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Pattern'
    ;;
  usage-exif-cli-machine-scene-capture)
    exif --machine-readable --tag=SceneCaptureType "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Landscape'
    ;;
  usage-exif-cli-extract-thumbnail-jpeg-magic)
    exif --extract-thumbnail --output="$tmpdir/thumb.jpg" "$img"
    validator_require_file "$tmpdir/thumb.jpg"
    head -c 3 "$tmpdir/thumb.jpg" | od -An -t x1 | tr -d ' \n' >"$tmpdir/magic"
    validator_assert_contains "$tmpdir/magic" 'ffd8ff'
    ;;
  *)
    printf 'unknown libexif tenth-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
