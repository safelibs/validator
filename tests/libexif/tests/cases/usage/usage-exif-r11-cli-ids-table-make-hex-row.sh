#!/usr/bin/env bash
# @testcase: usage-exif-r11-cli-ids-table-make-hex-row
# @title: exif --ids prints the hex tag id table with 0x010f mapping to Canon
# @description: Runs exif --ids without a tag selector and verifies the hex-id table includes the row "0x010f|Canon" (Make tag id), confirming the table view replaces decoded tag names with their numeric hex identifiers.
# @timeout: 60
# @tags: usage, ids, table
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ids "$img" >"$tmpdir/out"
grep -E '^0x010f\|Canon$' "$tmpdir/out" >/dev/null
