#!/usr/bin/env bash
# @testcase: usage-exif-cli-ifd-exif
# @title: exif CLI EXIF IFD
# @description: Runs the exif CLI against the EXIF IFD and verifies exposure metadata is decoded.
# @timeout: 180
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="ifd-exif"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ifd=EXIF "$img" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Exposure Time'
