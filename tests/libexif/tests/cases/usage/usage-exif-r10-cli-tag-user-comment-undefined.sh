#!/usr/bin/env bash
# @testcase: usage-exif-r10-cli-tag-user-comment-undefined
# @title: exif --tag=UserComment reports the Undefined-format payload
# @description: Runs exif --tag=UserComment against the canon fixture and verifies the readout names tag id 0x9286 in IFD EXIF, reports the Undefined format (format code 7) with the 264-byte payload size libexif sees in the entry header so callers can detect the present-but-empty UserComment slot before consuming it.
# @timeout: 60
# @tags: usage, metadata, comment
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=UserComment "$img" >"$tmpdir/pretty.out"
validator_assert_contains "$tmpdir/pretty.out" "0x9286"
validator_assert_contains "$tmpdir/pretty.out" "UserComment"
validator_assert_contains "$tmpdir/pretty.out" "IFD 'EXIF'"
validator_assert_contains "$tmpdir/pretty.out" "Format: 7 ('Undefined')"
validator_assert_contains "$tmpdir/pretty.out" "Components: 264"
validator_assert_contains "$tmpdir/pretty.out" "Size: 264"
