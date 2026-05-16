#!/usr/bin/env bash
# @testcase: usage-exif-r21-cli-show-description-resolution-unit
# @title: exif --show-description --tag=ResolutionUnit mentions XResolution YResolution and inches
# @description: Runs exif --show-description --tag=ResolutionUnit --ifd=0 on the Canon fixture and asserts the captured description mentions both "XResolution" and "YResolution" along with "inches", locking in libexif's bundled description text for the ResolutionUnit tag (distinct from previous r20 description coverage of ExposureTime).
# @timeout: 60
# @tags: usage, exif, show-description, resolution-unit, r21
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --show-description --tag=ResolutionUnit --ifd=0 "$img" >"$tmpdir/out" 2>"$tmpdir/err"
validator_assert_contains "$tmpdir/out" 'XResolution'
validator_assert_contains "$tmpdir/out" 'YResolution'
validator_assert_contains "$tmpdir/out" 'inches'
