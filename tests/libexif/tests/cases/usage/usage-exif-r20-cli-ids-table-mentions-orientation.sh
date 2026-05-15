#!/usr/bin/env bash
# @testcase: usage-exif-r20-cli-ids-table-mentions-orientation
# @title: exif --ids on canon fixture mentions the Orientation tag hex id 0x0112
# @description: Runs exif --ids on the canon fixture and asserts the captured numeric-id table contains the literal hex id "0x0112" (the canonical EXIF Orientation tag id) - locking in libexif's --ids enumeration emitting the Orientation row's hex id.
# @timeout: 60
# @tags: usage, exif, ids, orientation, hex-id, r20
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ids "$img" >"$tmpdir/out" 2>"$tmpdir/err"
validator_assert_contains "$tmpdir/out" '0x0112'
