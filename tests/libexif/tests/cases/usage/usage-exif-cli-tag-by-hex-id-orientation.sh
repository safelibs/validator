#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-by-hex-id-orientation
# @title: exif --tag=0x0112 selects Orientation by numeric ID
# @description: Runs exif with --tag specified as the bare hexadecimal Orientation tag id (0x0112) and verifies the client resolves the numeric id to the same entry it reports under the symbolic name, including the IFD '0' provenance line, the format Short triple, the single-component descriptor, and the human-readable Right-top value from the canon fixture.
# @timeout: 60
# @tags: usage, metadata, tag-id
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-tag-by-hex-id-orientation"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=0x0112 "$img" >"$tmpdir/by-hex.out"
exif --tag=Orientation "$img" >"$tmpdir/by-name.out"

# Both must locate the entry and report identical body content.
validator_assert_contains "$tmpdir/by-hex.out" "exists in IFD '0'"
validator_assert_contains "$tmpdir/by-hex.out" "Tag: 0x112 ('Orientation')"
validator_assert_contains "$tmpdir/by-hex.out" "Format: 3 ('Short')"
validator_assert_contains "$tmpdir/by-hex.out" 'Components: 1'
validator_assert_contains "$tmpdir/by-hex.out" 'Value: Right-top'

if ! diff -u "$tmpdir/by-name.out" "$tmpdir/by-hex.out" >"$tmpdir/diff"; then
  printf 'expected --tag=0x0112 and --tag=Orientation to produce identical output\n' >&2
  cat "$tmpdir/diff" >&2
  exit 1
fi
