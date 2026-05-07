#!/usr/bin/env bash
# @testcase: usage-exif-r14-cli-xml-output-make-canon
# @title: exif --xml-output emits <Manufacturer>Canon</Manufacturer> for the canon fixture
# @description: Runs exif --xml-output against the canon fixture and verifies the resulting stream contains the exact substring "<Manufacturer>Canon</Manufacturer>", asserting libexif emits a "Manufacturer" XML element for the Make tag (using the semantic name rather than the on-disk "Make" label) with both opening and closing tags around the literal "Canon".
# @timeout: 60
# @tags: usage, xml-output, make
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --xml-output "$img" >"$tmpdir/xml.out"
validator_assert_contains "$tmpdir/xml.out" "<Manufacturer>Canon</Manufacturer>"
