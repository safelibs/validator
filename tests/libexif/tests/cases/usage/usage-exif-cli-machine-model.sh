#!/usr/bin/env bash
# @testcase: usage-exif-cli-machine-model
# @title: exif machine-readable model
# @description: Prints the Model tag in machine-readable form and verifies the camera model.
# @timeout: 180
# @tags: usage, jpeg, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-machine-model"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=Model "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Canon PowerShot S70'
