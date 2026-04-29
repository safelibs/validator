#!/usr/bin/env bash
# @testcase: usage-exif-cli-ifd-zero
# @title: exif IFD zero listing
# @description: Reads the primary IFD from a JPEG fixture and checks manufacturer metadata.
# @timeout: 180
# @tags: usage, jpeg, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-ifd-zero"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ifd=0 "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Manufacturer'
validator_assert_contains "$tmpdir/out" 'Canon'
