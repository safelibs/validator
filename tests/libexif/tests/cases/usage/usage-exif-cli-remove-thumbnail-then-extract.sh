#!/usr/bin/env bash
# @testcase: usage-exif-cli-remove-thumbnail-then-extract
# @title: exif --remove-thumbnail then --extract-thumbnail reports absence
# @description: Strips the embedded thumbnail from a copy of the canon fixture with --remove-thumbnail, then runs --extract-thumbnail against the rewritten file and verifies the client exits non-zero with a does not contain a thumbnail diagnostic and produces no output file, while the original fixture still yields a thumbnail.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-remove-thumbnail-then-extract"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

# Baseline: original fixture yields a 4-byte thumbnail placeholder
exif --extract-thumbnail --output="$tmpdir/before.jpg" "$img" >"$tmpdir/before.log"
validator_assert_contains "$tmpdir/before.log" 'Wrote file'
validator_require_file "$tmpdir/before.jpg"

# Strip the thumbnail from a copy
cp "$img" "$tmpdir/source.jpg"
exif --remove-thumbnail --output="$tmpdir/stripped.jpg" "$tmpdir/source.jpg" >"$tmpdir/strip.log"
validator_assert_contains "$tmpdir/strip.log" 'Wrote file'
validator_require_file "$tmpdir/stripped.jpg"

# Re-extracting from the stripped copy must fail with the absence diagnostic
set +e
exif --extract-thumbnail --output="$tmpdir/after.jpg" "$tmpdir/stripped.jpg" \
  >"$tmpdir/after.stdout" 2>"$tmpdir/after.stderr"
rc=$?
set -e

if (( rc == 0 )); then
  printf 'expected extract-thumbnail to fail after remove-thumbnail, got rc=0\n' >&2
  cat "$tmpdir/after.stdout" "$tmpdir/after.stderr" >&2
  exit 1
fi

cat "$tmpdir/after.stdout" "$tmpdir/after.stderr" >"$tmpdir/after.all"
validator_assert_contains "$tmpdir/after.all" 'does not contain a thumbnail'

if [[ -e "$tmpdir/after.jpg" ]]; then
  printf 'unexpected after.jpg written despite missing thumbnail\n' >&2
  exit 1
fi
