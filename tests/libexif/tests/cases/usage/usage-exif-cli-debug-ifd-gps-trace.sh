#!/usr/bin/env bash
# @testcase: usage-exif-cli-debug-ifd-gps-trace
# @title: exif --debug --ifd=GPS scoped trace
# @description: Runs the exif client with --debug --ifd=GPS against the canon fixture and verifies the loader still emits its scanning banner and the IFD 0 entry count alongside the user-friendly error indicating the GPS IFD has no entries.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-debug-ifd-gps-trace"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --debug --ifd=GPS "$img" >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" 'ExifLoader: Scanning'
validator_assert_contains "$tmpdir/out" 'ExifData: Found EXIF header'
validator_assert_contains "$tmpdir/out" 'ExifData: IFD 0 at 8.'
validator_assert_contains "$tmpdir/out" 'ExifData: Loading 9 entries...'
