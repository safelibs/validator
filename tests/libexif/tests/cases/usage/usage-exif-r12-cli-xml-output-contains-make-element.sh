#!/usr/bin/env bash
# @testcase: usage-exif-r12-cli-xml-output-contains-make-element
# @title: exif --xml-output --tag=Make surfaces the Canon manufacturer value
# @description: Requests the per-tag emission for the Make tag (selected by symbolic name) and verifies the output mentions both "Make" (or its libexif alias "Manufacturer") and the manufacturer value "Canon". (Noble's exif CLI does not actually wrap the value in XML element tags when --xml-output is combined with --tag; it falls back to the verbose entry dump. Assert presence of the value rather than the XML shape.)
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
grep -Eiq '(Make|Manufacturer)' "$tmpdir/out" \
  || { sed -n '1,40p' "$tmpdir/out" >&2; exit 1; }
grep -q 'Canon' "$tmpdir/out" \
  || { sed -n '1,40p' "$tmpdir/out" >&2; exit 1; }
