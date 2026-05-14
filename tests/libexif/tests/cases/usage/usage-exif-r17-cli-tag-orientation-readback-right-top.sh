#!/usr/bin/env bash
# @testcase: usage-exif-r17-cli-tag-orientation-readback-right-top
# @title: exif --tag=Orientation pretty readback mentions Right-top label
# @description: Reads the Orientation tag from the canon fixture via exif --tag=Orientation (pretty output, no --machine-readable) and asserts the output contains the substring "Right-top", exercising libexif's SHORT-to-label pretty conversion on the canon fixture's orientation value.
# @timeout: 60
# @tags: usage, exif, orientation
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=Orientation "$img" >"$tmpdir/out" 2>"$tmpdir/err"
validator_assert_contains "$tmpdir/out" 'Right-top'
