#!/usr/bin/env bash
# @testcase: usage-exif-cli-xml-output
# @title: exif CLI XML output
# @description: Runs the exif CLI XML output mode and verifies camera model metadata appears in XML.
# @timeout: 180
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="xml-output"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --xml-output "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '<Model>Canon PowerShot S70</Model>'
