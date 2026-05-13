#!/usr/bin/env bash
# @testcase: usage-exif-r16-cli-xml-output-make-mentioned
# @title: exif --xml-output for canon fixture wraps Canon in a Make element pair
# @description: Runs exif --xml-output against the canon fixture and asserts the stream contains "<Make>Canon</Make>" exactly, locking the libexif XML serialiser's element-name normalisation for the Make tag on this specific fixture.
# @timeout: 60
# @tags: usage, xml-output, make
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --xml-output "$img" >"$tmpdir/xml"
validator_assert_contains "$tmpdir/xml" "<Make>Canon</Make>"
