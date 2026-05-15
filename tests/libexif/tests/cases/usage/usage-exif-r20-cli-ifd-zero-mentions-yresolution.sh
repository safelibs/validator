#!/usr/bin/env bash
# @testcase: usage-exif-r20-cli-ifd-zero-mentions-yresolution
# @title: exif --ifd=0 pretty output mentions the Y-Resolution tag header
# @description: Runs exif --ifd=0 on the canon fixture and asserts the captured pretty-table output contains the literal "Y-Resolution" tag header (IFD0 always carries YResolution on the canon fixture), exercising libexif's IFD0 enumeration via the pretty-mode renderer with a tag distinct from prior round coverage.
# @timeout: 60
# @tags: usage, exif, ifd0, yresolution, r20
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ifd=0 "$img" >"$tmpdir/out" 2>"$tmpdir/err"
validator_assert_contains "$tmpdir/out" 'Y-Resolution'
