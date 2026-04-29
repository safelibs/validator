#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-ycbcr-positioning-batch11
# @title: exif YCbCrPositioning tag
# @description: Reads the YCbCrPositioning tag with exif.
# @timeout: 180
# @tags: usage, exif, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-tag-ycbcr-positioning-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=YCbCrPositioning "$img" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Value:'
