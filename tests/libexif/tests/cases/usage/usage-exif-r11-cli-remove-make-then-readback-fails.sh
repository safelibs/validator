#!/usr/bin/env bash
# @testcase: usage-exif-r11-cli-remove-make-then-readback-fails
# @title: exif --remove drops Make so a subsequent --tag readback exits non-zero
# @description: Removes the Make (Manufacturer) tag from IFD 0, writes the JPEG to a new path, then asserts that re-reading the Make tag fails with "does not contain tag 'Make'." on stderr and a non-zero exit, exercising the destructive --remove path on a tag known to exist in the source fixture.
# @timeout: 60
# @tags: usage, remove, manufacturer
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"
cp "$img" "$tmpdir/in.jpg"

exif --remove --tag=Make --output="$tmpdir/out.jpg" "$tmpdir/in.jpg" >"$tmpdir/write.log"
validator_assert_contains "$tmpdir/write.log" "Wrote file"

set +e
exif --tag=Make --machine-readable "$tmpdir/out.jpg" >"$tmpdir/value" 2>"$tmpdir/err"
status=$?
set -e

if (( status == 0 )); then
  printf 'expected non-zero exit after Make removal, got status 0\n' >&2
  cat "$tmpdir/value" >&2
  exit 1
fi

validator_assert_contains "$tmpdir/err" "does not contain tag 'Make'"
