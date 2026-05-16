#!/usr/bin/env bash
# @testcase: usage-exif-r21-cli-ifd-one-compression-value-jpeg
# @title: exif --ifd=1 --tag=Compression formats the canon thumbnail compression as JPEG
# @description: Runs exif --ifd=1 --tag=Compression on the Canon fixture and asserts the captured output contains "Format: 3" with "JPEG compression" - locking in libexif's IFD1 (thumbnail) compression formatting for SHORT format with value 6 rendered as the JPEG compression label.
# @timeout: 60
# @tags: usage, exif, ifd-one, compression, r21
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ifd=1 --tag=Compression "$img" >"$tmpdir/out" 2>"$tmpdir/err"
validator_assert_contains "$tmpdir/out" "Format: 3"
validator_assert_contains "$tmpdir/out" "JPEG compression"
