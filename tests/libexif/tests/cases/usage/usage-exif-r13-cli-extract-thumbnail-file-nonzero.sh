#!/usr/bin/env bash
# @testcase: usage-exif-r13-cli-extract-thumbnail-file-nonzero
# @title: exif --extract-thumbnail writes a non-zero file at the requested --output path
# @description: Runs exif --extract-thumbnail --output=path against the canon fixture and verifies the file was created at exactly that path with non-zero size, asserting libexif's thumbnail-extract path honours the --output destination.
# @timeout: 60
# @tags: usage, extract-thumbnail
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

target="$tmpdir/thumb.jpg"
exif --extract-thumbnail --output="$target" "$img" >"$tmpdir/log"
validator_assert_contains "$tmpdir/log" "Wrote file"

validator_require_file "$target"
size=$(stat -c '%s' "$target")
if (( size <= 0 )); then
  printf 'expected non-zero thumbnail at %s, got size=%s\n' "$target" "$size" >&2
  exit 1
fi
