#!/usr/bin/env bash
# @testcase: usage-exif-cli-ifd-zero-model
# @title: exif IFD0 model tag
# @description: Dumps the IFD0 tag set and verifies the camera model entry is present in the textual output.
# @timeout: 180
# @tags: usage, jpeg, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-ifd-zero-model"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ifd=0 "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Model'
validator_assert_contains "$tmpdir/out" 'Canon PowerShot S70'
