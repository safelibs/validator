#!/usr/bin/env bash
# @testcase: usage-exif-r11-cli-ifd-zero-table-includes-manufacturer
# @title: exif --ifd=0 ASCII table contains the Manufacturer row with pipe separator
# @description: Renders the IFD 0 dump and verifies the row "Manufacturer        |Canon" appears with the libexif pipe-aligned column layout, confirming the IFD-scoped table view is emitted and the Manufacturer ASCII value is reachable.
# @timeout: 60
# @tags: usage, ifd, table
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ifd=0 "$img" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" "Manufacturer"
grep -E '^Manufacturer[[:space:]]+\|Canon$' "$tmpdir/out" >/dev/null
