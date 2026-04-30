#!/usr/bin/env bash
# @testcase: usage-exif-cli-extract-thumbnail-bytewise-equal
# @title: exif --extract-thumbnail is byte-stable across re-runs
# @description: Runs exif --extract-thumbnail twice against the canon fixture writing to two distinct output files, verifies both are non-empty, and asserts that the two extracted thumbnail files are byte-for-byte equal so callers can rely on deterministic re-extraction.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-extract-thumbnail-bytewise-equal"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --extract-thumbnail --output="$tmpdir/first.thumb" "$img" >"$tmpdir/first.log"
validator_assert_contains "$tmpdir/first.log" 'Wrote file'
validator_require_file "$tmpdir/first.thumb"

exif --extract-thumbnail --output="$tmpdir/second.thumb" "$img" >"$tmpdir/second.log"
validator_assert_contains "$tmpdir/second.log" 'Wrote file'
validator_require_file "$tmpdir/second.thumb"

first_size=$(stat -c '%s' "$tmpdir/first.thumb")
second_size=$(stat -c '%s' "$tmpdir/second.thumb")
if (( first_size <= 0 )); then
  printf 'expected non-empty first.thumb, got size=%d\n' "$first_size" >&2
  exit 1
fi
if (( first_size != second_size )); then
  printf 'thumbnail size mismatch across runs: first=%d second=%d\n' \
    "$first_size" "$second_size" >&2
  exit 1
fi

if ! cmp -s "$tmpdir/first.thumb" "$tmpdir/second.thumb"; then
  printf 're-extracted thumbnails are not byte-equal\n' >&2
  od -An -t x1 "$tmpdir/first.thumb" | head -n 4 >&2
  od -An -t x1 "$tmpdir/second.thumb" | head -n 4 >&2
  exit 1
fi

# Cross-check the SHA-256 digest of both runs
first_sha=$(sha256sum "$tmpdir/first.thumb" | awk '{print $1}')
second_sha=$(sha256sum "$tmpdir/second.thumb" | awk '{print $1}')
if [[ "$first_sha" != "$second_sha" ]]; then
  printf 'thumbnail SHA-256 mismatch: first=%s second=%s\n' "$first_sha" "$second_sha" >&2
  exit 1
fi
