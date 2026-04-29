#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-datetime-sed
# @title: exif tag date time via sed
# @description: Extracts the exif DateTime tag value through shell text processing and verifies the parsed timestamp.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-tag-datetime-sed"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

extract_value() {
  sed -n 's/.*Value: //p' "$1" >"$tmpdir/value"
  test -s "$tmpdir/value"
}

exif --tag=DateTime "$img" >"$tmpdir/out"
extract_value "$tmpdir/out"
validator_assert_contains "$tmpdir/value" '2009:10:10 16:42:32'
