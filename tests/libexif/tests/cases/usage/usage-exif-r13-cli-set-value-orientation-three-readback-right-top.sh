#!/usr/bin/env bash
# @testcase: usage-exif-r13-cli-set-value-orientation-three-readback-right-top
# @title: exif --set-value Orientation=3 round-trips to "Bottom-right" on readback
# @description: Sets Orientation in IFD 0 to the numeric value 3 (180-degree rotation, value range 1..8) via --set-value, writes a new JPEG via --output, and verifies the formatted "Value: Bottom-right" line appears on readback, asserting libexif maps the SHORT 3 to its canonical 180-degree label.
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

exif --tag=Orientation --ifd=0 --set-value='3' \
  --output="$tmpdir/out.jpg" "$tmpdir/in.jpg" >"$tmpdir/write.log"
validator_assert_contains "$tmpdir/write.log" "Wrote file"

exif --tag=Orientation --ifd=0 "$tmpdir/out.jpg" >"$tmpdir/show.out"
validator_assert_contains "$tmpdir/show.out" "Value: Bottom-right"
