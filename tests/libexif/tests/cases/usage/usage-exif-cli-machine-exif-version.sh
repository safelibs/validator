#!/usr/bin/env bash
# @testcase: usage-exif-cli-machine-exif-version
# @title: exif machine ExifVersion
# @description: Reads ExifVersion via exif --machine-readable and verifies that Exif Version 2.2 is reported.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-machine-exif-version"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=ExifVersion "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Exif Version 2.2'
