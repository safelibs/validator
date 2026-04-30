#!/usr/bin/env bash
# @testcase: usage-exif-cli-remove-make-tag
# @title: exif --remove drops Make from a copy
# @description: Copies the canon JPEG fixture to a tmpdir and removes the Make tag with exif --remove, verifying the Make tag is gone while Model remains intact.
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
exif --remove --tag=Make --ifd=0 --output="$tmpdir/stripped.jpg" "$tmpdir/source.jpg" >"$tmpdir/write.log"
validator_require_file "$tmpdir/stripped.jpg"
validator_assert_contains "$tmpdir/write.log" "Wrote file"

# Make tag must be gone in the new copy
exif --tag=Make "$tmpdir/stripped.jpg" >"$tmpdir/make.out" 2>&1 || true
validator_assert_contains "$tmpdir/make.out" "does not contain tag 'Make'"

# Model tag must still be present and unchanged
exif --tag=Model "$tmpdir/stripped.jpg" >"$tmpdir/model.out"
validator_assert_contains "$tmpdir/model.out" "Value: Canon PowerShot S70"
