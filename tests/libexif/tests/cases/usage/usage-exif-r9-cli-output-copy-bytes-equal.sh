#!/usr/bin/env bash
# @testcase: usage-exif-r9-cli-output-copy-bytes-equal
# @title: exif --remove with --output writes a JPEG copy
# @description: Calls exif --remove --tag=Make --output to produce a modified copy and verifies the new file is a non-empty JPEG that exif can still parse.
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
# --output is honored on a modifying operation. Remove the Make tag (present in
# this fixture) and require exif to write the resulting JPEG to copy.jpg.
exif --remove --tag=Make --output "$tmpdir/copy.jpg" "$tmpdir/src.jpg" >/dev/null 2>&1

validator_require_file "$tmpdir/copy.jpg"
[[ -s "$tmpdir/copy.jpg" ]]
# Output starts with the JPEG SOI magic (FFD8) and remains parseable.
head -c 2 "$tmpdir/copy.jpg" | od -An -tx1 | tr -d ' \n' | grep -q '^ffd8'
exif "$tmpdir/copy.jpg" >"$tmpdir/dump" 2>&1
validator_assert_contains "$tmpdir/dump" 'EXIF tags'
