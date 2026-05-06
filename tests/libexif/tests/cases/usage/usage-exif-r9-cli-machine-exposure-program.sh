#!/usr/bin/env bash
# @testcase: usage-exif-r9-cli-machine-exposure-program
# @title: exif --machine-readable for ExposureProgram
# @description: Reads ExposureProgram in machine-readable mode and verifies the output is a non-empty single-line value (no Value: prefix).
# @timeout: 60
# @tags: usage, metadata, machine-readable
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=ExposureProgram "$img" >"$tmpdir/out" 2>&1
[[ -s "$tmpdir/out" ]]
# machine-readable should not include the human "Value:" label.
! grep -q 'Value:' "$tmpdir/out"
