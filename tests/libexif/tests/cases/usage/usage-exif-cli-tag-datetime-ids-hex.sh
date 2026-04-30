#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-datetime-ids-hex
# @title: exif --tag=DateTime cross-checked against the 0x0132 hex id
# @description: Reads the top-level DateTime tag with the exif client both by symbolic name and via the --ids dump that prints numeric tag ids in hex against the canon fixture, verifying the canonical timestamp 2009:10:10 16:42:32 surfaces from the symbolic --tag=DateTime call and that the --ids listing of IFD 0 contains the 0x0132 DateTime tag id paired with the same timestamp.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-tag-datetime-ids-hex"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

# Symbolic --tag=DateTime: text mode prints the record with the timestamp
exif --tag=DateTime "$img" >"$tmpdir/symbolic.out"
validator_assert_contains "$tmpdir/symbolic.out" '2009:10:10 16:42:32'

# --ids dumps the IFD 0 listing with hex tag ids; DateTime is 0x0132
exif --ids --ifd=0 "$img" >"$tmpdir/ids.out"
validator_assert_contains "$tmpdir/ids.out" '0x0132'

# The same timestamp must also surface in the IFD 0 listing
validator_assert_contains "$tmpdir/ids.out" '2009:10:10 16:42:32'
