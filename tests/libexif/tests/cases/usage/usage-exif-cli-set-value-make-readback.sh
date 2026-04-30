#!/usr/bin/env bash
# @testcase: usage-exif-cli-set-value-make-readback
# @title: exif --set-value rewrites Make tag
# @description: Uses exif --set-value with --ifd=0 to replace the Make tag on a copy of the canon fixture and reads the new value back from the rewritten JPEG.
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
exif --ifd=0 --tag=Make --set-value='Mock Camera' --output="$tmpdir/edited.jpg" "$tmpdir/source.jpg" >"$tmpdir/write.log"
validator_assert_contains "$tmpdir/write.log" "Wrote file"
validator_require_file "$tmpdir/edited.jpg"

# Original fixture must remain untouched
exif --tag=Make "$img" >"$tmpdir/original.out"
validator_assert_contains "$tmpdir/original.out" "Value: Canon"

# Rewritten copy must report the new value
exif --tag=Make "$tmpdir/edited.jpg" >"$tmpdir/edited.out"
validator_assert_contains "$tmpdir/edited.out" "Value: Mock Camera"
validator_assert_contains "$tmpdir/edited.out" "Components: 12"
