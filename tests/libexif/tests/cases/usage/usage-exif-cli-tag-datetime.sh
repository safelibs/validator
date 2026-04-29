#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-datetime
# @title: exif CLI DateTime tag
# @description: Runs the exif CLI to read the image DateTime tag from a JPEG fixture.
# @timeout: 180
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="tag-datetime"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=DateTime "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '2009:10:10 16:42:32'
