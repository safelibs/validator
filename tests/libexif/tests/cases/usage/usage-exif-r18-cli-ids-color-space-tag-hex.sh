#!/usr/bin/env bash
# @testcase: usage-exif-r18-cli-ids-color-space-tag-hex
# @title: exif --ids --machine-readable --tag=ColorSpace emits 0xa001 row
# @description: Runs exif --ids --machine-readable --tag=ColorSpace and asserts the captured single-line output contains the literal hex tag id "0xa001" (the EXIF spec id for ColorSpace), exercising the combined --ids + --machine-readable rendering path on a known tag.
# @timeout: 60
# @tags: usage, exif, ids, machine-readable, colorspace, r18
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ids --machine-readable --tag=ColorSpace "$img" >"$tmpdir/out" 2>"$tmpdir/err"
if ! LC_ALL=C grep -q '0xa001' "$tmpdir/out"; then
  echo 'expected hex id 0xa001 in --ids --machine-readable ColorSpace output' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
