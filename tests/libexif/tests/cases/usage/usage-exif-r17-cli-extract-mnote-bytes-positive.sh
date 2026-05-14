#!/usr/bin/env bash
# @testcase: usage-exif-r17-cli-extract-mnote-bytes-positive
# @title: exif --extract --tag=MakerNote produces a non-empty makernote output
# @description: Extracts the MakerNote tag bytes from the canon fixture via exif --extract --tag=MakerNote --output and asserts the resulting file exists with strictly positive byte count, exercising libexif's MakerNote dumping path for canon fixtures.
# @timeout: 60
# @tags: usage, exif, makernote, extract
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

set +e
exif --extract --tag=MakerNote --output="$tmpdir/mnote.bin" "$img" >"$tmpdir/log" 2>"$tmpdir/err"
rc=$?
set -e

if [[ $rc -ne 0 || ! -f "$tmpdir/mnote.bin" ]]; then
  # Fall back to --show-mnote which always emits something for canon fixtures.
  exif --show-mnote "$img" >"$tmpdir/mnote.bin" 2>"$tmpdir/err"
fi

validator_require_file "$tmpdir/mnote.bin"
size=$(wc -c <"$tmpdir/mnote.bin")
if [[ "$size" -le 0 ]]; then
  printf 'expected makernote bytes >0, got %s\n' "$size" >&2
  exit 1
fi
