#!/usr/bin/env bash
# @testcase: usage-exif-r17-cli-xml-output-manufacturer-element
# @title: exif --xml-output includes a Manufacturer element substring
# @description: Runs exif --xml-output on the canon fixture and asserts the emitted XML contains the literal substring "<Manufacturer>" (the noble libexif XML serialiser names the Make tag element as Manufacturer), exercising the XML metadata emitter.
# @timeout: 60
# @tags: usage, exif, xml, manufacturer
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --xml-output "$img" >"$tmpdir/out.xml"
validator_assert_contains "$tmpdir/out.xml" '<Manufacturer>'
