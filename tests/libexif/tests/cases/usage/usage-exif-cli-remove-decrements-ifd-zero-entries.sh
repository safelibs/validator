#!/usr/bin/env bash
# @testcase: usage-exif-cli-remove-decrements-ifd-zero-entries
# @title: exif --remove decrements IFD 0 entry count
# @description: Removes the Make tag from a copy of the canon JPEG and confirms via --debug that IFD 0 now reports 8 entries instead of the original 9.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

# Baseline: original fixture has 9 entries in IFD 0
exif --debug "$img" >"$tmpdir/before.log" 2>&1
validator_assert_contains "$tmpdir/before.log" "ExifData: Loading 9 entries..."

cp "$img" "$tmpdir/source.jpg"
exif --remove --tag=Make --ifd=0 --output="$tmpdir/stripped.jpg" "$tmpdir/source.jpg" >/dev/null

exif --debug "$tmpdir/stripped.jpg" >"$tmpdir/after.log" 2>&1
validator_assert_contains "$tmpdir/after.log" "ExifData: Loading 8 entries..."
