#!/usr/bin/env bash
# @testcase: usage-exif-r10-cli-xml-output-shutter-speed-element
# @title: exif --xml-output exposes Shutter_Speed as an XML element
# @description: Runs exif --xml-output against the canon fixture and verifies the serialized XML stream contains the Shutter_Speed element carrying the composed APEX rendering 0.00 EV (1 sec.), confirming libexif maps the SRational ShutterSpeedValue tag to a sanitized XML element name.
# @timeout: 60
# @tags: usage, metadata, xml
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --xml-output "$img" >"$tmpdir/out"

# Document opens with the <exif> root element libexif emits
validator_assert_contains "$tmpdir/out" '<exif>'
validator_assert_contains "$tmpdir/out" '</exif>'

# Shutter_Speed element carries the composed reading byte-exact
validator_assert_contains "$tmpdir/out" '<Shutter_Speed>0.00 EV (1 sec.)</Shutter_Speed>'

# The element name uses underscores, not the original space-separated label
if grep -Fq '<Shutter Speed>' "$tmpdir/out"; then
  printf 'unexpected unsanitized element name <Shutter Speed>\n' >&2
  exit 1
fi
