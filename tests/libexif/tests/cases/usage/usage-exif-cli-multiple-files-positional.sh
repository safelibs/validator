#!/usr/bin/env bash
# @testcase: usage-exif-cli-multiple-files-positional
# @title: exif accepts multiple positional file arguments
# @description: Runs the exif client with two positional JPEG paths that point at the same canon fixture and verifies the client emits one EXIF tags table per argument by counting the per-file header banner. Pins libexif's positional file iteration contract on Ubuntu 24.04 for callers that batch multiple JPEGs in a single invocation.
# @timeout: 120
# @tags: usage, metadata, batch
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-multiple-files-positional"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

# Hard-link to a sibling path so each argument is a distinct file path.
copy="$tmpdir/canon-copy.jpg"
cp "$img" "$copy"
validator_require_file "$copy"

exif "$img" "$copy" >"$tmpdir/out"

# Each input must produce its own EXIF tags header line.
header_count=$(grep -c "^EXIF tags in '" "$tmpdir/out")
if (( header_count != 2 )); then
  printf 'expected 2 per-file EXIF headers, got %d\n' "$header_count" >&2
  sed -n '1,80p' "$tmpdir/out" >&2
  exit 1
fi

validator_assert_contains "$tmpdir/out" "EXIF tags in '$img' ('Intel' byte order):"
validator_assert_contains "$tmpdir/out" "EXIF tags in '$copy' ('Intel' byte order):"
validator_assert_contains "$tmpdir/out" 'Manufacturer        |Canon'
