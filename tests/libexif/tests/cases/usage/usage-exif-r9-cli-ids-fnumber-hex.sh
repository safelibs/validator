#!/usr/bin/env bash
# @testcase: usage-exif-r9-cli-ids-fnumber-hex
# @title: exif --ids displays FNumber tag id
# @description: Calls exif --ids on the fixture and verifies a four-digit hex tag identifier appears alongside FNumber in the rendered table.
# @timeout: 60
# @tags: usage, metadata, ids
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ids --tag=FNumber "$img" >"$tmpdir/out" 2>&1
# FNumber tag id is 0x829d.
validator_assert_contains "$tmpdir/out" '0x829d'
