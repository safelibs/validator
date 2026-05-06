#!/usr/bin/env bash
# @testcase: usage-exif-r9-cli-xml-tag-fnumber-value
# @title: exif --xml-output renders an XML EXIF dump
# @description: Runs exif --xml-output against the fixture and verifies the output is wrapped in <exif>...</exif> root tags carrying recognizable EXIF entries.
# @timeout: 60
# @tags: usage, metadata, xml
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --xml-output "$img" >"$tmpdir/out" 2>&1
[[ -s "$tmpdir/out" ]]
grep -Eq '<exif[^A-Za-z]' "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '</exif>'
validator_assert_contains "$tmpdir/out" '<Exposure_Mode>'
