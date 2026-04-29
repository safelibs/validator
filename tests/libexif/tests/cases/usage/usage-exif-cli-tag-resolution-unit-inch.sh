#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-resolution-unit-inch
# @title: exif tag resolution unit inch
# @description: Reads the ResolutionUnit EXIF tag with the exif client and verifies that inch units are reported.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="usage-exif-cli-tag-resolution-unit-inch"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=ResolutionUnit "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Inch'
