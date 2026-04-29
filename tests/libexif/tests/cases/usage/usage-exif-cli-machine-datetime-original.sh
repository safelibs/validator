#!/usr/bin/env bash
# @testcase: usage-exif-cli-machine-datetime-original
# @title: exif machine DateTimeOriginal
# @description: Exercises exif machine datetimeoriginal through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-machine-datetime-original"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=DateTimeOriginal "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '2009:10:10 16:42:32'
