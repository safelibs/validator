#!/usr/bin/env bash
# @testcase: usage-exif-r15-cli-xml-output-exposure-time-element
# @title: exif --xml-output emits <Exposure_Time>1 sec.</Exposure_Time> for the canon fixture
# @description: Runs exif --xml-output against the canon fixture and verifies the resulting stream contains the exact substring "<Exposure_Time>1 sec.</Exposure_Time>" (libexif normalises the "Exposure Time" tag name into the underscore-joined element name), asserting an XML element with the formatted RATIONAL "1 sec." is emitted for the ExposureTime tag.
# @timeout: 60
# @tags: usage, xml-output, exposure-time
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --xml-output "$img" >"$tmpdir/xml.out"
validator_assert_contains "$tmpdir/xml.out" "<Exposure_Time>1 sec.</Exposure_Time>"
