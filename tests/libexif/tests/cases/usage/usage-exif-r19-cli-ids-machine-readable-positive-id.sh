#!/usr/bin/env bash
# @testcase: usage-exif-r19-cli-ids-machine-readable-positive-id
# @title: exif --ids -t Model verbose output emits a 0x0110 hex tag id line
# @description: Runs exif --ids -t Model on the canon fixture and asserts the captured stdout contains the literal hex string "0x110" or "0x0110" (EXIF spec id for Model), exercising libexif's --ids verbose tag identifier rendering for IFD0 Model.
# @timeout: 60
# @tags: usage, exif, ids, model, r19
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ids -t Model "$img" >"$tmpdir/out" 2>"$tmpdir/err"

if ! LC_ALL=C grep -Eq '0x0?110\b' "$tmpdir/out"; then
  echo 'expected 0x110 / 0x0110 tag id in --ids -t Model output' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
