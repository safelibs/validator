#!/usr/bin/env bash
# @testcase: usage-exif-r9-cli-xml-tag-fnumber-value
# @title: exif --xml-output exposes FNumber payload
# @description: Runs exif --xml-output --tag=FNumber against the fixture and verifies the rendered XML contains an FNumber element wrapping a value.
# @timeout: 60
# @tags: usage, metadata, xml
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --xml-output --tag=FNumber "$img" >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" '<FNumber'
validator_assert_contains "$tmpdir/out" '</FNumber>'
