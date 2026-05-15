#!/usr/bin/env bash
# @testcase: usage-exif-r20-cli-set-value-orientation-roundtrip-numeric
# @title: exif --set-value Orientation=3 then pretty readback labels it Bottom-right
# @description: Copies the canon fixture, runs exif --tag=Orientation --ifd=0 --set-value=3 --output to rewrite the file, then reads back via exif --tag=Orientation --ifd=0 and asserts the captured pretty output contains "Bottom-right" - locking in libexif's set-value writer plus its interpreted label rendering for orientation=3.
# @timeout: 60
# @tags: usage, exif, set-value, orientation, roundtrip, r20
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

cp -a "$img" "$tmpdir/in.jpg"
exif --tag=Orientation --ifd=0 --set-value=3 --output="$tmpdir/out.jpg" "$tmpdir/in.jpg" >"$tmpdir/wlog" 2>"$tmpdir/werr"
validator_require_file "$tmpdir/out.jpg"

exif --tag=Orientation --ifd=0 "$tmpdir/out.jpg" >"$tmpdir/r.txt" 2>"$tmpdir/rerr"
validator_assert_contains "$tmpdir/r.txt" 'Bottom-right'
