#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload=${1:?missing exif CLI workload}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

case "$workload" in
    list-tags)
        exif "$img" | tee "$tmpdir/out"
        validator_assert_contains "$tmpdir/out" 'Manufacturer'
        validator_assert_contains "$tmpdir/out" 'Canon'
        ;;
    machine-readable)
        exif --machine-readable "$img" | tee "$tmpdir/out"
        validator_assert_contains "$tmpdir/out" 'Manufacturer'
        validator_assert_contains "$tmpdir/out" 'Canon'
        ;;
    tag-make)
        exif --tag=Make "$img" | tee "$tmpdir/out"
        validator_assert_contains "$tmpdir/out" 'Value: Canon'
        ;;
    tag-model)
        exif --tag=Model "$img" | tee "$tmpdir/out"
        validator_assert_contains "$tmpdir/out" 'Canon PowerShot S70'
        ;;
    maker-note)
        exif --show-mnote "$img" | tee "$tmpdir/out"
        validator_assert_contains "$tmpdir/out" 'MakerNote contains'
        ;;
    extract-thumbnail)
        exif --extract-thumbnail --output="$tmpdir/thumb.jpg" "$img"
        file "$tmpdir/thumb.jpg" | tee "$tmpdir/out"
        validator_assert_contains "$tmpdir/out" 'JPEG image data'
        ;;
    ifd-exif)
        exif --ifd=EXIF "$img" | tee "$tmpdir/out"
        validator_assert_contains "$tmpdir/out" 'Exposure Time'
        ;;
    xml-output)
        exif --xml-output "$img" | tee "$tmpdir/out"
        validator_assert_contains "$tmpdir/out" '<Model>Canon PowerShot S70</Model>'
        ;;
    *)
        printf 'unknown exif CLI workload: %s\n' "$workload" >&2
        exit 2
        ;;
esac
