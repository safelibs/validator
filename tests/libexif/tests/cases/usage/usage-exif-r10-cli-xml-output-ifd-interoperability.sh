#!/usr/bin/env bash
# @testcase: usage-exif-r10-cli-xml-output-ifd-interoperability
# @title: exif --xml-output --ifd=Interoperability scopes elements to that IFD
# @description: Runs exif --xml-output --ifd=Interoperability against the canon fixture and verifies the XML stream contains the four Interoperability_Index, Interoperability_Version, RelatedImageWidth, and RelatedImageLength elements while excluding IFD-zero entries like Manufacturer or Orientation, confirming libexif honors the IFD scope when emitting XML.
# @timeout: 60
# @tags: usage, metadata, xml, ifd
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --xml-output --ifd=Interoperability "$img" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" '<exif>'
validator_assert_contains "$tmpdir/out" '</exif>'
validator_assert_contains "$tmpdir/out" '<Interoperability_Index>R98</Interoperability_Index>'
validator_assert_contains "$tmpdir/out" '<Interoperability_Version>0100</Interoperability_Version>'
validator_assert_contains "$tmpdir/out" '<RelatedImageWidth>640</RelatedImageWidth>'
validator_assert_contains "$tmpdir/out" '<RelatedImageLength>480</RelatedImageLength>'

# IFD-zero / EXIF-IFD entries must NOT appear in the scoped output
for forbidden in '<Manufacturer>' '<Orientation>' '<F-Number>' '<Aperture>'; do
  if grep -Fq "$forbidden" "$tmpdir/out"; then
    printf 'expected scoped XML to omit %s\n' "$forbidden" >&2
    cat "$tmpdir/out" >&2
    exit 1
  fi
done
