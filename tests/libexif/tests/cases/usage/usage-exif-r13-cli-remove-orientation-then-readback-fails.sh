#!/usr/bin/env bash
# @testcase: usage-exif-r13-cli-remove-orientation-then-readback-fails
# @title: exif --remove of Orientation drops the tag so a follow-up read exits non-zero
# @description: Removes the Orientation tag from a copy of the canon fixture with --remove --tag=Orientation, then attempts a follow-up --tag=Orientation readback and verifies the second invocation exits non-zero with "does not contain tag" on stderr, asserting libexif's destructive remove path on a SHORT-typed tag.
# @timeout: 60
# @tags: usage, remove, orientation
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"
cp "$img" "$tmpdir/in.jpg"

exif --remove --tag=Orientation --ifd=0 --output="$tmpdir/out.jpg" "$tmpdir/in.jpg" >"$tmpdir/write.log"
validator_assert_contains "$tmpdir/write.log" "Wrote file"

set +e
exif --tag=Orientation --ifd=0 "$tmpdir/out.jpg" >"$tmpdir/value" 2>"$tmpdir/err"
status=$?
set -e

if (( status == 0 )); then
  printf 'expected non-zero exit after Orientation removal, got status 0\n' >&2
  cat "$tmpdir/value" >&2
  exit 1
fi

validator_assert_contains "$tmpdir/err" "does not contain tag"
