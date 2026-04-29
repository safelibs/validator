#!/usr/bin/env bash
# @testcase: usage-exif-cli-ifd-exif-fnumber
# @title: exif IFD EXIF F number
# @description: Exercises exif ifd exif f number through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-ifd-exif-fnumber"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ifd=EXIF "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'F-Number'
