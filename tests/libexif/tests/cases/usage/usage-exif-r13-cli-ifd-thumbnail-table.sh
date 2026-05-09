#!/usr/bin/env bash
# @testcase: usage-exif-r13-cli-ifd-thumbnail-table
# @title: exif --ifd=1 selects the Thumbnail IFD and prints its tag table
# @description: Runs exif with --ifd=1 (the Thumbnail IFD per libexif's IFD numbering) and verifies the output mentions Thumbnail in some form (either "EXIF tags in 'Thumbnail'" or just "Thumbnail") and surfaces a Compression entry, asserting the IFD-1 selector reaches the libexif Thumbnail directory.
# @timeout: 60
# @tags: usage, ifd-one, thumbnail
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ifd=1 "$img" >"$tmpdir/out"
# Noble's exif prints "IFD '1' (Thumbnail)" without the "EXIF tags in" phrase
# that earlier builds used; accept any line that mentions Thumbnail.
grep -q -i 'Thumbnail' "$tmpdir/out" || { sed -n '1,40p' "$tmpdir/out" >&2; exit 1; }
validator_assert_contains "$tmpdir/out" "Compression"
