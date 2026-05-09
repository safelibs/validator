#!/usr/bin/env bash
# @testcase: usage-exif-r12-cli-xml-output-contains-make-element
# @title: exif --xml-output --tag=Make emits Canon wrapped in an XML element
# @description: Requests the XML emission for the Make tag (selected by symbolic name) and verifies the resulting document contains an element wrapping the literal "Canon" — libexif's descriptive element name varies across builds (Manufacturer/Make/etc.), so assert the text is present inside angle brackets rather than pinning the tag name.
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
# Match either <Manufacturer>Canon</Manufacturer> or <Make>Canon</Make> (or
# any other libexif-chosen element name).
grep -Eq '<[A-Za-z][A-Za-z0-9_]*>Canon</[A-Za-z][A-Za-z0-9_]*>' "$tmpdir/out" \
  || { sed -n '1,40p' "$tmpdir/out" >&2; exit 1; }
