#!/usr/bin/env bash
# @testcase: usage-exif-r12-cli-tag-numeric-id-make-hex
# @title: exif --tag=0x010f selects the Make tag by hex numeric id and matches the Make-by-name dump
# @description: Targets the Make tag by its numeric hex id 0x010f via --tag and verifies the output is byte-for-byte identical to --tag=Make, asserting libexif resolves numeric tag selectors equivalently to symbolic names.
# @timeout: 60
# @tags: usage, tag, hex-id
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=0x010f "$img" >"$tmpdir/by-hex.out"
exif --tag=Make "$img" >"$tmpdir/by-name.out"
validator_assert_contains "$tmpdir/by-hex.out" "Tag: 0x10f ('Make')"
validator_assert_contains "$tmpdir/by-hex.out" "Canon"

if ! diff -u "$tmpdir/by-name.out" "$tmpdir/by-hex.out" >"$tmpdir/diff"; then
  printf 'expected --tag=0x010f and --tag=Make to produce identical output\n' >&2
  cat "$tmpdir/diff" >&2
  exit 1
fi
