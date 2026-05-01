#!/usr/bin/env bash
# @testcase: usage-exif-cli-show-description-gps-latitude
# @title: exif --show-description GPSLatitude in GPS IFD
# @description: Invokes exif --show-description --ifd=GPS --tag=GPSLatitude against the canon fixture and confirms the GPS subdirectory dispatch resolves to tag id 0x0002 with symbolic name GPSLatitude and the libexif documentation snippet expressed as three RATIONAL values giving the degrees, minutes, and seconds.
# @timeout: 60
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-show-description-gps-latitude"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --show-description --ifd=GPS --tag=GPSLatitude "$img" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" '0x0002'
validator_assert_contains "$tmpdir/out" "'GPSLatitude'"
validator_assert_contains "$tmpdir/out" 'three RATIONAL values giving the degrees, minutes, and seconds'
