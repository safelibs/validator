#!/usr/bin/env bash
# @testcase: usage-exif-r12-cli-xml-output-contains-make-element
# @title: exif --xml-output --tag=Make emits the <Manufacturer>Canon</Manufacturer> element
# @description: Requests the XML emission for the Make tag (selected by symbolic name) and verifies the resulting document contains "<Manufacturer>Canon</Manufacturer>", confirming libexif uses the descriptive tag title rather than the bare TIFF name when emitting per-tag XML elements.
# @timeout: 60
# @tags: usage, xml-output, make
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --xml-output --tag=Make "$img" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" "<Manufacturer>Canon</Manufacturer>"
