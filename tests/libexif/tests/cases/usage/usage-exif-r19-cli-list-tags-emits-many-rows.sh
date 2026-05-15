#!/usr/bin/env bash
# @testcase: usage-exif-r19-cli-list-tags-emits-many-rows
# @title: exif -l on canon fixture emits at least twenty non-blank table rows
# @description: Runs exif -l on the canon fixture and asserts the captured stdout has at least 20 non-blank lines (libexif's tag list view always enumerates several tens of rows on a real EXIF-bearing JPEG), exercising the libexif full-tag enumeration path.
# @timeout: 60
# @tags: usage, exif, list-tags, count, r19
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif -l "$img" >"$tmpdir/out" 2>"$tmpdir/err"
count=$(LC_ALL=C grep -cE '[^[:space:]]' "$tmpdir/out" || true)
if [[ "$count" -lt 20 ]]; then
  printf 'expected >=20 non-blank lines, got %s\n' "$count" >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
