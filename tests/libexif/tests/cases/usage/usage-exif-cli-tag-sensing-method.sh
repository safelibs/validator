#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-sensing-method
# @title: exif tag sensing method
# @description: Reads the SensingMethod EXIF tag with the exif client and verifies that the expected sensor type is reported.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="usage-exif-cli-tag-sensing-method"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=SensingMethod "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'One-chip color area sensor'
