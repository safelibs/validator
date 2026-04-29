#!/usr/bin/env bash
# @testcase: usage-exif-cli-xml-model
# @title: exif XML model tag
# @description: Emits XML metadata and verifies the model element for the sample JPEG is present.
# @timeout: 180
# @tags: usage, jpeg, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-xml-model"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --xml-output "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '<Model>Canon PowerShot S70</Model>'
