#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-interoperability-index
# @title: exif tag interoperability index
# @description: Reads the InteroperabilityIndex EXIF tag with the exif client and verifies that the R98 marker is reported.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="usage-exif-cli-tag-interoperability-index"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=InteroperabilityIndex "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'R98'
