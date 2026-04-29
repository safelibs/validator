#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-compression-jpeg
# @title: exif tag compression JPEG
# @description: Reads the Compression EXIF tag with the exif client and verifies that JPEG compression is reported for the sample image.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="usage-exif-cli-tag-compression-jpeg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=Compression "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'JPEG compression'
