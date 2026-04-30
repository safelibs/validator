#!/usr/bin/env bash
# @testcase: usage-exif-cli-ids-orientation-hex
# @title: exif --ids reports Orientation hex tag id
# @description: Runs the exif client with --ids to print numeric tag identifiers and verifies the Orientation tag id 0x112 with its Right-top value.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ids --tag=Orientation "$img" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" "Tag: 0x112 ('Orientation')"
validator_assert_contains "$tmpdir/out" "Value: Right-top"
