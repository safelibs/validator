#!/usr/bin/env bash
# @testcase: usage-exif-r13-cli-set-value-artist-then-remove-readback-fails
# @title: exif --set-value Artist then --remove leaves the tag absent on the next readback
# @description: Adds an Artist tag with --set-value, confirms the readback returns the value, then runs --remove on the same tag and verifies the subsequent --tag=Artist invocation exits non-zero with "does not contain tag" on stderr, asserting libexif's set-then-remove sequence on an ASCII (Artist 0x013B) tag.
# @timeout: 60
# @tags: usage, set-value, remove, artist
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"
cp "$img" "$tmpdir/in.jpg"

exif --tag=Artist --ifd=0 --set-value='r13-artist' \
  --output="$tmpdir/with.jpg" "$tmpdir/in.jpg" >"$tmpdir/write.log"
validator_assert_contains "$tmpdir/write.log" "Wrote file"

exif --tag=Artist --machine-readable "$tmpdir/with.jpg" >"$tmpdir/before"
read -r before <"$tmpdir/before"
[[ "$before" == "r13-artist" ]] || {
  printf 'expected Artist=r13-artist before remove, got: %s\n' "$before" >&2
  exit 1
}

exif --remove --tag=Artist --output="$tmpdir/after.jpg" "$tmpdir/with.jpg" >"$tmpdir/remove.log"
validator_assert_contains "$tmpdir/remove.log" "Wrote file"

set +e
exif --tag=Artist --machine-readable "$tmpdir/after.jpg" >"$tmpdir/value" 2>"$tmpdir/err"
status=$?
set -e

if (( status == 0 )); then
  printf 'expected non-zero exit after Artist removal, got status 0\n' >&2
  cat "$tmpdir/value" >&2
  exit 1
fi

validator_assert_contains "$tmpdir/err" "does not contain tag"
