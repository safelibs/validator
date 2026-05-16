#!/usr/bin/env bash
# @testcase: usage-exif-r21-cli-show-description-iso-speed-ratings
# @title: exif --show-description --tag=ISOSpeedRatings prints the ISO 12232 description
# @description: Runs exif --show-description --tag=ISOSpeedRatings --ifd=EXIF on the Canon fixture and asserts the captured description mentions both the "ISO Speed" tag label and the "12232" standard reference - locking in libexif's bundled human-readable description text for the ISO Speed Ratings tag.
# @timeout: 60
# @tags: usage, exif, show-description, iso, r21
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --show-description --tag=ISOSpeedRatings --ifd=EXIF "$img" >"$tmpdir/out" 2>"$tmpdir/err"
validator_assert_contains "$tmpdir/out" 'ISO Speed'
validator_assert_contains "$tmpdir/out" '12232'
