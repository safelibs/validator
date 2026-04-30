#!/usr/bin/env bash
# @testcase: usage-exif-cli-extract-remove-reextract-state
# @title: exif extract then remove-thumbnail then re-extract sequence
# @description: Walks the canon fixture through extract-thumbnail, remove-thumbnail on a copy, and a re-extract attempt against the stripped copy, verifying the first extraction produces a non-empty file, the strip succeeds, and the second extraction fails with a does not contain a thumbnail diagnostic, while a fresh extract from the original still succeeds.
# @timeout: 180
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-extract-remove-reextract-state"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

# Step 1: extract from original
exif --extract-thumbnail --output="$tmpdir/first.thumb" "$img" >"$tmpdir/first.log"
validator_assert_contains "$tmpdir/first.log" 'Wrote file'
validator_require_file "$tmpdir/first.thumb"
first_size=$(stat -c '%s' "$tmpdir/first.thumb")
if (( first_size <= 0 )); then
  printf 'expected first.thumb to be non-empty, got size=%d\n' "$first_size" >&2
  exit 1
fi

# Step 2: copy the original and remove its thumbnail
cp "$img" "$tmpdir/source.jpg"
exif --remove-thumbnail --output="$tmpdir/stripped.jpg" "$tmpdir/source.jpg" >"$tmpdir/strip.log"
validator_assert_contains "$tmpdir/strip.log" 'Wrote file'
validator_require_file "$tmpdir/stripped.jpg"

# Step 3: re-extract from stripped copy must fail
set +e
exif --extract-thumbnail --output="$tmpdir/second.thumb" "$tmpdir/stripped.jpg" \
  >"$tmpdir/second.stdout" 2>"$tmpdir/second.stderr"
rc=$?
set -e

if (( rc == 0 )); then
  printf 'expected re-extract on stripped copy to fail, got rc=0\n' >&2
  cat "$tmpdir/second.stdout" "$tmpdir/second.stderr" >&2
  exit 1
fi
cat "$tmpdir/second.stdout" "$tmpdir/second.stderr" >"$tmpdir/second.all"
validator_assert_contains "$tmpdir/second.all" 'does not contain a thumbnail'

if [[ -e "$tmpdir/second.thumb" ]]; then
  printf 'unexpected second.thumb written despite missing thumbnail\n' >&2
  exit 1
fi

# Step 4: a fresh extract from the untouched original must still succeed and match step 1
exif --extract-thumbnail --output="$tmpdir/third.thumb" "$img" >"$tmpdir/third.log"
validator_assert_contains "$tmpdir/third.log" 'Wrote file'
validator_require_file "$tmpdir/third.thumb"
if ! cmp -s "$tmpdir/first.thumb" "$tmpdir/third.thumb"; then
  printf 'fresh extract from untouched original diverged from initial extract\n' >&2
  exit 1
fi
