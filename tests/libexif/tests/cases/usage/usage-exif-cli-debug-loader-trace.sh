#!/usr/bin/env bash
# @testcase: usage-exif-cli-debug-loader-trace
# @title: exif --debug emits loader trace
# @description: Runs the exif client with --debug and verifies the loader announces the IFD 0 entry count and named entries from the canon fixture.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --debug "$img" >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" "ExifLoader: Scanning"
validator_assert_contains "$tmpdir/out" "ExifData: Found EXIF header"
validator_assert_contains "$tmpdir/out" "ExifData: IFD 0 at 8."
validator_assert_contains "$tmpdir/out" "ExifData: Loading 9 entries..."
validator_assert_contains "$tmpdir/out" "Loading entry 0x10f ('Make')..."
validator_assert_contains "$tmpdir/out" "Loading entry 0x110 ('Model')..."
