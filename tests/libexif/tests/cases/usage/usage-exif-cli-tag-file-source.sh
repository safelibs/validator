#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-file-source
# @title: exif tag file source
# @description: Reads the FileSource EXIF tag with the exif client and verifies that the DSC source marker is reported.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="usage-exif-cli-tag-file-source"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=FileSource "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'DSC'
