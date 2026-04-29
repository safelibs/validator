#!/usr/bin/env bash
# @testcase: usage-exif-cli-flash-tag
# @title: exif Flash tag
# @description: Reads the Flash EXIF tag from a JPEG fixture and checks that a value is present.
# @timeout: 180
# @tags: usage, jpeg, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-flash-tag"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=Flash "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Value:'
