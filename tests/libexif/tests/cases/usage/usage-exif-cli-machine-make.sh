#!/usr/bin/env bash
# @testcase: usage-exif-cli-machine-make
# @title: exif machine-readable make
# @description: Prints the Make tag in machine-readable form and verifies the manufacturer.
# @timeout: 180
# @tags: usage, jpeg, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-machine-make"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=Make "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Canon'
