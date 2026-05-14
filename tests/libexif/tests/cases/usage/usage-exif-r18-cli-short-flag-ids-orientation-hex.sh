#!/usr/bin/env bash
# @testcase: usage-exif-r18-cli-short-flag-ids-orientation-hex
# @title: exif -i --tag=Orientation includes the 0x0112 hex id row
# @description: Runs exif -i --tag=Orientation (short alias for --ids) on the canon fixture and asserts the pretty output contains the literal hex tag id "0x112" (the spec id for Orientation in IFD0) alongside the Right-top decoded label, exercising libexif's --ids rendering through the short -i flag (distinct from existing long-flag --ids coverage).
# @timeout: 60
# @tags: usage, exif, ids, short-flag, orientation, r18
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif -i --tag=Orientation "$img" >"$tmpdir/out" 2>"$tmpdir/err"
if ! LC_ALL=C grep -q '0x112' "$tmpdir/out"; then
  echo 'expected hex id 0x112 in exif -i --tag=Orientation output' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
validator_assert_contains "$tmpdir/out" 'Right-top'
