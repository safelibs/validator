#!/usr/bin/env bash
# @testcase: usage-exif-r9-cli-show-mnote-canon
# @title: exif --show-mnote prints Canon makernote
# @description: Runs exif --show-mnote on a Canon makernote fixture and verifies non-empty maker note output is produced.
# @timeout: 60
# @tags: usage, metadata, makernote
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --show-mnote "$img" >"$tmpdir/out" 2>&1
[[ -s "$tmpdir/out" ]]
# Output should mention something Canon-makernote-specific, but at minimum produces multiple lines.
total=$(wc -l <"$tmpdir/out")
[[ "$total" -gt 1 ]]
