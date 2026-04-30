#!/usr/bin/env bash
# @testcase: usage-exif-cli-xml-output-tag-orientation
# @title: exif --xml-output exposes Orientation alongside other elements
# @description: Runs the exif client with --xml-output against the canon fixture and verifies the serialized XML stream contains the Orientation element with the Right-top value plus the Manufacturer element so both tag entries are surfaced; cross-checks the plain --tag=Orientation lookup reports the same Right-top value.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-xml-output-tag-orientation"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

# Plain --tag=Orientation lookup: the textual output must report the
# Right-top orientation value.
exif --tag=Orientation "$img" >"$tmpdir/text.out"
validator_assert_contains "$tmpdir/text.out" 'Right-top'

# --xml-output dumps the full set of EXIF tags as XML elements.
exif --xml-output "$img" >"$tmpdir/full.out"
validator_assert_contains "$tmpdir/full.out" '<Orientation>Right-top</Orientation>'
validator_assert_contains "$tmpdir/full.out" '<Manufacturer>Canon</Manufacturer>'

full_size=$(stat -c '%s' "$tmpdir/full.out")
if (( full_size <= 0 )); then
  printf 'expected non-empty XML output\n' >&2
  exit 1
fi
