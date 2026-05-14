#!/usr/bin/env bash
# @testcase: usage-exif-r17-cli-machine-image-width-640
# @title: exif --machine-readable --tag=ImageWidth on canon fixture exits zero
# @description: Reads the ImageWidth tag (IFD0/IFD1) from the canon fixture in machine-readable mode and asserts the exit status is zero, exercising libexif's SHORT/LONG-typed tag readback through exif's --tag= option.
# @timeout: 60
# @tags: usage, exif, image-width
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

set +e
exif --machine-readable --tag=ImageWidth "$img" >"$tmpdir/out" 2>"$tmpdir/err"
rc=$?
set -e
if [[ $rc -ne 0 ]]; then
  printf 'expected exit zero, got rc=%d\n' "$rc" >&2
  cat "$tmpdir/err" >&2
  exit 1
fi
