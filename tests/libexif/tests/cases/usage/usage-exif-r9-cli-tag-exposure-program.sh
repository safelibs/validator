#!/usr/bin/env bash
# @testcase: usage-exif-r9-cli-tag-exposure-program
# @title: exif --tag=ExposureProgram reads tag
# @description: Reads the ExposureProgram EXIF tag from the Canon makernote fixture and verifies a value field is rendered to stdout.
# @timeout: 60
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=ExposureProgram "$img" >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" 'Value:'
