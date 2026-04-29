#!/usr/bin/env bash
# @testcase: usage-exif-cli-machine-datetime
# @title: exif machine DateTime
# @description: Exercises exif machine datetime through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-machine-datetime"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=DateTime "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '2009:10:10 16:42:32'
