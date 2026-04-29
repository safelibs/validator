#!/usr/bin/env bash
# @testcase: usage-exif-cli-maker-note
# @title: exif CLI maker note
# @description: Runs the exif CLI to decode maker-note metadata from a JPEG fixture.
# @timeout: 180
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="maker-note"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --show-mnote "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'MakerNote contains'
