#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-exposure-time-ids-ifd-exif
# @title: exif --ids --ifd=EXIF --tag=ExposureTime reports 0x829a
# @description: Runs the exif client with --ids --ifd=EXIF --tag=ExposureTime against the canon fixture and verifies the EXIF-IFD scoped readout reports the numeric tag id 0x829a paired with the ExposureTime symbolic name and the 1 sec. value.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-tag-exposure-time-ids-ifd-exif"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ids --ifd=EXIF --tag=ExposureTime "$img" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" "Tag: 0x829a ('ExposureTime')"
validator_assert_contains "$tmpdir/out" "Value: 1 sec."
