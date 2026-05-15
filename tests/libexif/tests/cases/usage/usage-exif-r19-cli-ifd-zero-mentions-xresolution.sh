#!/usr/bin/env bash
# @testcase: usage-exif-r19-cli-ifd-zero-mentions-xresolution
# @title: exif --ifd=0 pretty output mentions the X-Resolution tag header
# @description: Runs exif --ifd=0 on the canon fixture and asserts the captured pretty-table output contains the literal "X-Resolution" tag header (IFD0 always carries XResolution on the canon fixture), exercising libexif's IFD0 enumeration in pretty mode.
# @timeout: 60
# @tags: usage, exif, ifd0, xresolution, r19
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ifd=0 "$img" >"$tmpdir/out" 2>"$tmpdir/err"
validator_assert_contains "$tmpdir/out" 'X-Resolution'
