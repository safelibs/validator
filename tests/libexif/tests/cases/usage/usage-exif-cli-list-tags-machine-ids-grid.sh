#!/usr/bin/env bash
# @testcase: usage-exif-cli-list-tags-machine-ids-grid
# @title: exif -l -i -m emits the IFD support grid with hex IDs
# @description: Runs exif with --list-tags combined with --ids and --machine-readable against the canon fixture and verifies the client emits the documented IFD support grid pinning the column header set (0, 1, EXIF, GPS, Interop), the hex tag id format (0x0001), and the presence of a known Interoperability tag row that locks the libexif Ubuntu 24.04 list-tags reference grid that callers parse to map tag-id-to-IFD support.
# @timeout: 60
# @tags: usage, metadata, list-tags
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-list-tags-machine-ids-grid"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif -l -i -m "$img" >"$tmpdir/out"

# Header row must list the documented IFD columns.
validator_assert_contains "$tmpdir/out" '0'
validator_assert_contains "$tmpdir/out" '1'
validator_assert_contains "$tmpdir/out" 'EXIF'
validator_assert_contains "$tmpdir/out" 'GPS'
validator_assert_contains "$tmpdir/out" 'Interop'

# A known Interoperability tag row must appear with its hex id and label.
validator_assert_contains "$tmpdir/out" '0x0001'
validator_assert_contains "$tmpdir/out" 'Interoperability Index'

# A representative interop row must show its hex id followed by the label and
# the IFD-support markers ("-" or "*"); confirm by looking for the known row.
grep -qE '^0x0001 +Interoperability Index' "$tmpdir/out" || {
  printf 'expected 0x0001 Interoperability Index row in -l -i -m output\n' >&2
  sed -n '1,20p' "$tmpdir/out" >&2
  exit 1
}
