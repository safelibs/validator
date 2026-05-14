#!/usr/bin/env bash
# @testcase: usage-exif-r18-cli-ifd-exif-mentions-color-space
# @title: exif --ifd=EXIF pretty output mentions the ColorSpace tag header
# @description: Runs exif --ifd=EXIF on the canon fixture and asserts the pretty-table output contains the literal "Color Space" tag header (the EXIF IFD always carries this row on the canon fixture), exercising libexif's EXIF-IFD tag enumeration in pretty mode.
# @timeout: 60
# @tags: usage, exif, ifd, color-space, r18
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ifd=EXIF "$img" >"$tmpdir/out" 2>"$tmpdir/err"
validator_assert_contains "$tmpdir/out" 'Color Space'
