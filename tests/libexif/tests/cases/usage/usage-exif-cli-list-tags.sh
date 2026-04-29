#!/usr/bin/env bash
# @testcase: usage-exif-cli-list-tags
# @title: exif CLI lists camera tags
# @description: Runs the exif CLI on a JPEG fixture and reads camera tag output.
# @timeout: 180
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="list-tags"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Manufacturer'
validator_assert_contains "$tmpdir/out" 'Canon'
