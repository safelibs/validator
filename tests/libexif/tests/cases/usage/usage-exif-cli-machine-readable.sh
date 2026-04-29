#!/usr/bin/env bash
# @testcase: usage-exif-cli-machine-readable
# @title: exif CLI machine output
# @description: Runs the exif CLI in machine-readable mode and reads structured tag output.
# @timeout: 180
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="machine-readable"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Manufacturer'
validator_assert_contains "$tmpdir/out" 'Canon'
