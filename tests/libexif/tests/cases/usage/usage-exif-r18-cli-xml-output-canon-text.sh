#!/usr/bin/env bash
# @testcase: usage-exif-r18-cli-xml-output-canon-text
# @title: exif --xml-output contains the literal Canon manufacturer text
# @description: Runs exif --xml-output on the canon fixture and asserts the emitted XML contains the literal payload string ">Canon<" (the Manufacturer element's text content boundary), exercising libexif's XML element-text serialiser for IFD0 Make.
# @timeout: 60
# @tags: usage, exif, xml, canon, r18
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --xml-output "$img" >"$tmpdir/out.xml" 2>"$tmpdir/err"
validator_assert_contains "$tmpdir/out.xml" '>Canon'
