#!/usr/bin/env bash
# @testcase: usage-exif-cli-machine-focal-plane-x-resolution-batch11
# @title: exif machine focal plane X resolution
# @description: Reads the focal-plane X resolution tag in machine-readable form with exif.
# @timeout: 180
# @tags: usage, exif, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-machine-focal-plane-x-resolution-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=FocalPlaneXResolution "$img" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '2253'
