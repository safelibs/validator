#!/usr/bin/env bash
# @testcase: usage-exif-r14-cli-extract-thumbnail-custom-output-jpeg-magic
# @title: exif --extract-thumbnail --output=<nested-path> writes a file beginning with FFD8FF
# @description: Runs exif --extract-thumbnail with a custom --output path inside a freshly-created nested directory, verifies the requested file exists with non-zero size and that its first three bytes are exactly the JPEG magic FFD8FF, asserting libexif's thumbnail extraction honours custom output paths and emits a JPEG envelope.
# @timeout: 60
# @tags: usage, extract-thumbnail, custom-output
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

mkdir -p "$tmpdir/nested/dir"
target="$tmpdir/nested/dir/extracted.jpg"

exif --extract-thumbnail --output="$target" "$img" >"$tmpdir/log"
validator_assert_contains "$tmpdir/log" "Wrote file"
validator_require_file "$target"

size=$(stat -c '%s' "$target")
if (( size <= 0 )); then
  printf 'expected non-zero thumbnail at %s, got size=%s\n' "$target" "$size" >&2
  exit 1
fi

magic=$(head -c 3 "$target" | od -An -tx1 | tr -d ' \n')
if [[ "$magic" != "ffd8ff" ]]; then
  printf 'expected JPEG magic ffd8ff, got: %s\n' "$magic" >&2
  exit 1
fi
