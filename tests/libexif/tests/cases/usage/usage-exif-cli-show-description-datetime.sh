#!/usr/bin/env bash
# @testcase: usage-exif-cli-show-description-datetime
# @title: exif --show-description prints DateTime help
# @description: Asks the exif client for the DateTime tag description with --show-description --ifd=0 and verifies the standard EXIF documentation string is reported.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --show-description --tag=DateTime --ifd=0 "$img" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" "Tag 'Date and Time' (0x0132, 'DateTime')"
validator_assert_contains "$tmpdir/out" "date and time of image creation"
