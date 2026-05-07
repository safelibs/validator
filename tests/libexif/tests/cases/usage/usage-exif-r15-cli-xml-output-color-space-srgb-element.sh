#!/usr/bin/env bash
# @testcase: usage-exif-r15-cli-xml-output-color-space-srgb-element
# @title: exif --xml-output emits <Color_Space>sRGB</Color_Space> for the canon fixture
# @description: Runs exif --xml-output against the canon fixture and verifies the resulting stream contains the exact substring "<Color_Space>sRGB</Color_Space>" (libexif normalises tag names with spaces into underscore-joined element names), asserting an XML element with the textual SHORT label "sRGB" is emitted for the ColorSpace tag.
# @timeout: 60
# @tags: usage, xml-output, color-space
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --xml-output "$img" >"$tmpdir/xml.out"
validator_assert_contains "$tmpdir/xml.out" "<Color_Space>sRGB</Color_Space>"
