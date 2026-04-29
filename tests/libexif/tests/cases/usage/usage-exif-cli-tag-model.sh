#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-model
# @title: exif CLI model tag
# @description: Runs the exif CLI to read the camera Model tag from a JPEG fixture.
# @timeout: 180
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="tag-model"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=Model "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Canon PowerShot S70'
