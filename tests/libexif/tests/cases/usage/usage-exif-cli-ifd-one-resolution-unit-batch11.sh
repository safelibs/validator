#!/usr/bin/env bash
# @testcase: usage-exif-cli-ifd-one-resolution-unit-batch11
# @title: exif IFD1 resolution unit
# @description: Lists thumbnail IFD metadata and checks resolution unit details.
# @timeout: 180
# @tags: usage, exif, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-ifd-one-resolution-unit-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ifd=1 "$img" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Resolution Unit'
