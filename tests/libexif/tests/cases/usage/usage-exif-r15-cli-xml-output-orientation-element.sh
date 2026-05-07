#!/usr/bin/env bash
# @testcase: usage-exif-r15-cli-xml-output-orientation-element
# @title: exif --xml-output emits <Orientation>Right-top</Orientation> for the canon fixture
# @description: Runs exif --xml-output against the canon fixture and verifies the resulting stream contains the exact substring "<Orientation>Right-top</Orientation>", asserting libexif emits an "Orientation" XML element with both opening and closing tags wrapping the textual SHORT label "Right-top".
# @timeout: 60
# @tags: usage, xml-output, orientation
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --xml-output "$img" >"$tmpdir/xml.out"
validator_assert_contains "$tmpdir/xml.out" "<Orientation>Right-top</Orientation>"
