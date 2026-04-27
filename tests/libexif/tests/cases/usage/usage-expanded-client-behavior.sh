#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload=${1:?missing exif CLI workload}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

case "$workload" in
  usage-exif-cli-tag-compression-jpeg)
    exif --tag=Compression "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'JPEG compression'
    ;;
  usage-exif-cli-tag-resolution-unit-inch)
    exif --tag=ResolutionUnit "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Inch'
    ;;
  usage-exif-cli-tag-exif-version-22)
    exif --tag=ExifVersion "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Exif Version 2.2'
    ;;
  usage-exif-cli-tag-flashpix-version-10)
    exif --tag=FlashPixVersion "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'FlashPix Version 1.0'
    ;;
  usage-exif-cli-tag-components-configuration)
    exif --tag=ComponentsConfiguration "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Y Cb Cr -'
    ;;
  usage-exif-cli-tag-digital-zoom-ratio)
    exif --tag=DigitalZoomRatio "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '1.0000'
    ;;
  usage-exif-cli-tag-interoperability-index)
    exif --tag=InteroperabilityIndex "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'R98'
    ;;
  usage-exif-cli-tag-interoperability-version)
    exif --tag=InteroperabilityVersion "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '0100'
    ;;
  usage-exif-cli-tag-sensing-method)
    exif --tag=SensingMethod "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'One-chip color area sensor'
    ;;
  usage-exif-cli-tag-file-source)
    exif --tag=FileSource "$img" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'DSC'
    ;;
  *)
    printf 'unknown exif expanded usage case: %s\n' "$workload" >&2
    exit 2
    ;;
esac
