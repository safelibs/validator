#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-interoperability-version
# @title: exif tag interoperability version
# @description: Reads the InteroperabilityVersion EXIF tag with the exif client and verifies that the expected 0100 version string is reported.
# @timeout: 120
# @tags: usage
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="usage-exif-cli-tag-interoperability-version"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=InteroperabilityVersion "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '0100'
