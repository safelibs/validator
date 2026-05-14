#!/usr/bin/env bash
# @testcase: usage-exif-r18-cli-list-tags-make-and-model-present
# @title: exif --list-tags lists both Manufacturer and Model rows
# @description: Runs exif --list-tags on the canon fixture and asserts the catalog output contains rows for both the Manufacturer (Make) and Model tags, exercising libexif's tag enumeration without requiring a specific id format (distinct from --ids hex tests).
# @timeout: 60
# @tags: usage, exif, list-tags, r18
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --list-tags "$img" >"$tmpdir/out" 2>"$tmpdir/err"
validator_assert_contains "$tmpdir/out" 'Manufacturer'
validator_assert_contains "$tmpdir/out" 'Model'
