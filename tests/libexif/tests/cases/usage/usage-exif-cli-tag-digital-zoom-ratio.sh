#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-digital-zoom-ratio
# @title: exif tag digital zoom ratio
# @description: Reads the DigitalZoomRatio EXIF tag with the exif client and verifies that the expected 1.0000 ratio is reported.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="usage-exif-cli-tag-digital-zoom-ratio"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=DigitalZoomRatio "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '1.0000'
