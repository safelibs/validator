#!/usr/bin/env bash
# @testcase: usage-exif-cli-machine-maker-note-thumbnail
# @title: exif machine-readable maker note
# @description: Emits full machine-readable EXIF metadata and verifies Maker Note and ThumbnailSize rows from the structured output.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-machine-maker-note-thumbnail"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

extract_value() {
  sed -n 's/.*Value: //p' "$1" >"$tmpdir/value"
  test -s "$tmpdir/value"
}

exif --machine-readable "$img" >"$tmpdir/out"
grep -Fx $'Maker Note\t904 bytes undefined data' "$tmpdir/out" >"$tmpdir/maker"
grep -Fx $'ThumbnailSize\t4' "$tmpdir/out" >"$tmpdir/thumb"
