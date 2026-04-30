#!/usr/bin/env bash
# @testcase: usage-exif-cli-no-fixup-tag-make
# @title: exif --no-fixup keeps Make tag readable
# @description: Runs the exif client with --no-fixup so that no automatic tag repair is performed and verifies that the Make tag still parses to Canon from the canon fixture.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --no-fixup --tag=Make "$img" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" "EXIF entry 'Manufacturer'"
validator_assert_contains "$tmpdir/out" "Value: Canon"
