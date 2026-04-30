#!/usr/bin/env bash
# @testcase: usage-exif-cli-debug-no-fixup-loader-trace
# @title: exif --debug --no-fixup still emits loader trace
# @description: Runs the exif client with --debug --no-fixup against the canon fixture and verifies the loader still announces the EXIF header, IFD 0 offset, the 9-entry count, and the named Make and Model entries even with the no-fixup switch present.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-debug-no-fixup-loader-trace"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --debug --no-fixup "$img" >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" 'ExifLoader: Scanning'
validator_assert_contains "$tmpdir/out" 'ExifData: Found EXIF header'
validator_assert_contains "$tmpdir/out" 'ExifData: IFD 0 at 8.'
validator_assert_contains "$tmpdir/out" 'ExifData: Loading 9 entries...'
validator_assert_contains "$tmpdir/out" "Loading entry 0x10f ('Make')..."
validator_assert_contains "$tmpdir/out" "Loading entry 0x110 ('Model')..."

# Reading without --no-fixup must still show Manufacturer/Canon to confirm parse succeeded
validator_assert_contains "$tmpdir/out" 'Canon'
