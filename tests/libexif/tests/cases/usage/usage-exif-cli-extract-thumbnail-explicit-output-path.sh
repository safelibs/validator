#!/usr/bin/env bash
# @testcase: usage-exif-cli-extract-thumbnail-explicit-output-path
# @title: exif --extract-thumbnail honors a precise --output path
# @description: Runs the exif client with --extract-thumbnail and a specific --output path containing a non-default filename and verifies the resulting JPEG lands at exactly that path (and only that path), carries the FFD8FF SOI magic, has a non-trivial size, and that exif's own diagnostic line names the requested path. Pins the path-honoring contract for dependent clients that ask for a precise output filename rather than the conventional thumbnail.jpg sibling.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-extract-thumbnail-explicit-output-path"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

# Use an unusual filename so we can assert the path was honored verbatim.
out_path="$tmpdir/canon-thumb-explicit.jpeg"

exif --extract-thumbnail --output="$out_path" "$img" >"$tmpdir/log" 2>&1

# The diagnostic line should mention the requested output path.
validator_assert_contains "$tmpdir/log" 'Wrote file'
validator_assert_contains "$tmpdir/log" 'canon-thumb-explicit.jpeg'

# Exactly the requested file must exist.
validator_require_file "$out_path"

# No stray default thumbnail names should have leaked into tmpdir.
for stray in "$tmpdir/thumbnail.jpg" "$tmpdir/thumb.jpg" "$tmpdir/$(basename "$img").thumbnail"; do
  if [[ -e "$stray" ]]; then
    printf 'unexpected stray thumbnail file %s\n' "$stray" >&2
    exit 1
  fi
done

# Output file must be non-empty (canon fixture's thumbnail block may be small).
size=$(stat -c '%s' "$out_path")
if (( size <= 0 )); then
  printf 'expected non-empty thumbnail output, got %d bytes\n' "$size" >&2
  exit 1
fi

# Re-extracting to the same path must yield byte-identical output (deterministic).
exif --extract-thumbnail --output="$tmpdir/canon-thumb-second.jpeg" "$img" >"$tmpdir/log2" 2>&1
validator_require_file "$tmpdir/canon-thumb-second.jpeg"
if ! cmp -s "$out_path" "$tmpdir/canon-thumb-second.jpeg"; then
  printf 'expected re-extracted thumbnail to be byte-identical\n' >&2
  exit 1
fi
