#!/usr/bin/env bash
# @testcase: usage-exif-r20-cli-list-tags-make-row
# @title: exif -l on canon fixture emits a Manufacturer row
# @description: Runs exif -l on the canon fixture and asserts the captured tag table contains the literal "Manufacturer" row label (libexif's --list-tags localises Make as Manufacturer in IFD0 row labels) - locking in the IFD0 Manufacturer row in --list-tags output.
# @timeout: 60
# @tags: usage, exif, list-tags, manufacturer, r20
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif -l "$img" >"$tmpdir/out" 2>"$tmpdir/err"
validator_assert_contains "$tmpdir/out" 'Manufacturer'
