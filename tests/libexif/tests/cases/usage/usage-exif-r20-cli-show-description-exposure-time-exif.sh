#!/usr/bin/env bash
# @testcase: usage-exif-r20-cli-show-description-exposure-time-exif
# @title: exif --show-description ExposureTime in IFD EXIF resolves the canonical description
# @description: Runs exif --show-description --ifd=EXIF --tag=ExposureTime on the canon fixture and asserts the captured output mentions both the tag name "Exposure Time" and the hex id 0x829a (the canonical EXIF ExposureTime tag) - locking in libexif's --show-description resolution for the ExposureTime tag in IFD EXIF.
# @timeout: 60
# @tags: usage, exif, show-description, exposure-time, r20
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --show-description --ifd=EXIF --tag=ExposureTime "$img" >"$tmpdir/out" 2>"$tmpdir/err"
validator_assert_contains "$tmpdir/out" 'Exposure Time'
validator_assert_contains "$tmpdir/out" '0x829a'
