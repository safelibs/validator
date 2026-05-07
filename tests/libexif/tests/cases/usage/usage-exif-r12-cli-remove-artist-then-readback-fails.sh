#!/usr/bin/env bash
# @testcase: usage-exif-r12-cli-remove-artist-then-readback-fails
# @title: exif --remove drops a previously-set Artist so a subsequent readback fails
# @description: Writes an Artist tag with --set-value, then runs --remove on the same tag and asserts the next --tag readback exits non-zero with "does not contain tag 'Artist'." on stderr, exercising the destructive --remove on an Artist tag created in this run.
# @timeout: 60
# @tags: usage, remove, artist
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"
cp "$img" "$tmpdir/in.jpg"

exif --tag=Artist --ifd=0 --set-value='Photographer' --output="$tmpdir/with.jpg" "$tmpdir/in.jpg" >/dev/null
exif --tag=Artist --machine-readable "$tmpdir/with.jpg" >"$tmpdir/before"
read -r before <"$tmpdir/before"
[[ "$before" == "Photographer" ]] || { printf 'expected Artist before remove, got: %s\n' "$before" >&2; exit 1; }

exif --remove --tag=Artist --output="$tmpdir/after.jpg" "$tmpdir/with.jpg" >"$tmpdir/write.log"
validator_assert_contains "$tmpdir/write.log" "Wrote file"

set +e
exif --tag=Artist --machine-readable "$tmpdir/after.jpg" >"$tmpdir/value" 2>"$tmpdir/err"
status=$?
set -e

if (( status == 0 )); then
  printf 'expected non-zero exit after Artist removal, got status 0\n' >&2
  cat "$tmpdir/value" >&2
  exit 1
fi

validator_assert_contains "$tmpdir/err" "does not contain tag 'Artist'"
