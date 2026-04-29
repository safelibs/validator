#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-exif-version-22
# @title: exif tag ExifVersion 2.2
# @description: Reads the ExifVersion EXIF tag with the exif client and verifies that Exif Version 2.2 is reported.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="usage-exif-cli-tag-exif-version-22"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=ExifVersion "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Exif Version 2.2'
