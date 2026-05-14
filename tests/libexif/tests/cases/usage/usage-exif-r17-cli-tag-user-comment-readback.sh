#!/usr/bin/env bash
# @testcase: usage-exif-r17-cli-tag-user-comment-readback
# @title: exif --tag=UserComment readback on canon fixture exits zero
# @description: Reads the UserComment tag from the canon fixture via exif --tag=UserComment in machine-readable mode and asserts the command exits zero, exercising libexif's UNDEFINED-type tag readback path for ifd-exif tags.
# @timeout: 60
# @tags: usage, exif, user-comment
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

set +e
exif --machine-readable --tag=UserComment "$img" >"$tmpdir/out" 2>"$tmpdir/err"
rc=$?
set -e
if [[ $rc -ne 0 ]]; then
  printf 'expected --tag=UserComment to exit zero, got rc=%d\n' "$rc" >&2
  cat "$tmpdir/err" >&2
  exit 1
fi
