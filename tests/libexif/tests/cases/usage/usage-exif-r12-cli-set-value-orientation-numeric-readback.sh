#!/usr/bin/env bash
# @testcase: usage-exif-r12-cli-set-value-orientation-numeric-readback
# @title: exif --set-value rewrites Orientation to 8 and the readback labels it "Left-bottom"
# @description: Sets the Orientation tag in IFD 0 to the numeric value 8 (rotate 90 CCW, value range 1..8) via --set-value, then reads the tag back and verifies the formatted "Value: Left-bottom" line appears, asserting the SHORT-tag writer round-trips through libexif's interpreted value formatter.
# @timeout: 60
# @tags: usage, set-value, orientation
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"
cp "$img" "$tmpdir/in.jpg"

exif --tag=Orientation --ifd=0 --set-value='8' --output="$tmpdir/out.jpg" "$tmpdir/in.jpg" >"$tmpdir/write.log"
validator_assert_contains "$tmpdir/write.log" "Wrote file"

exif --tag=Orientation --ifd=0 "$tmpdir/out.jpg" >"$tmpdir/show.out"
validator_assert_contains "$tmpdir/show.out" "Value: Left-bottom"
