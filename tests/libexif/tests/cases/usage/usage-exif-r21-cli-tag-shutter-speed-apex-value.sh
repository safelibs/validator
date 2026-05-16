#!/usr/bin/env bash
# @testcase: usage-exif-r21-cli-tag-shutter-speed-apex-value
# @title: exif --tag=ShutterSpeedValue renders the APEX 1-second equivalent
# @description: Runs exif --tag=ShutterSpeedValue --ifd=EXIF on the Canon fixture and asserts the captured detailed output contains the APEX label "0.00 EV" along with "(1 sec.)" - locking in libexif's APEX shutter-speed formatting that pairs an EV value with the equivalent fractional/whole-second exposure on this fixture.
# @timeout: 60
# @tags: usage, exif, shutter-speed, apex, r21
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=ShutterSpeedValue --ifd=EXIF "$img" >"$tmpdir/out" 2>"$tmpdir/err"
validator_assert_contains "$tmpdir/out" '0.00 EV'
validator_assert_contains "$tmpdir/out" '(1 sec.)'
