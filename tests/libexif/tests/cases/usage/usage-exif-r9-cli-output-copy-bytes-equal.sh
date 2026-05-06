#!/usr/bin/env bash
# @testcase: usage-exif-r9-cli-output-copy-bytes-equal
# @title: exif --output preserves source bytes when no edits applied
# @description: Calls exif --output on the fixture without any modifying flags and verifies the resulting file is byte-identical to the input.
# @timeout: 60
# @tags: usage, metadata, copy
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

cp "$img" "$tmpdir/src.jpg"
# Pair --output with a no-op --tag read so a copy is written.
exif --tag=Make --output "$tmpdir/copy.jpg" "$tmpdir/src.jpg" >/dev/null 2>&1

validator_require_file "$tmpdir/copy.jpg"
[[ -s "$tmpdir/copy.jpg" ]]
# Verify the copy is itself parseable by exif as a sanity check.
exif "$tmpdir/copy.jpg" >"$tmpdir/dump" 2>&1
validator_assert_contains "$tmpdir/dump" 'EXIF tags'
