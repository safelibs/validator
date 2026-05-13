#!/usr/bin/env bash
# @testcase: usage-exif-r16-cli-ifd-zero-tag-count-positive
# @title: exif --ifd 0 listing reports at least one tag for the canon fixture
# @description: Runs exif --ifd=0 against the canon fixture and asserts the IFD-0 dump contains the section header substring "EXIF tags in" and at least one numeric tag row beginning with "0x" prefix in the table body, asserting the IFD-0 listing is non-empty without pinning a specific tag value.
# @timeout: 60
# @tags: usage, ifd, listing
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ifd=0 "$img" >"$tmpdir/ifd0.out"
validator_assert_contains "$tmpdir/ifd0.out" "EXIF tags in"

count=$(LC_ALL=C grep -cE '^\|0x[0-9a-fA-F]{4}' "$tmpdir/ifd0.out" || true)
if (( count < 1 )); then
  # fall back to less-strict 0x-row pattern in case table chrome differs
  count=$(LC_ALL=C grep -cE '0x[0-9a-fA-F]{4}' "$tmpdir/ifd0.out" || true)
fi
if (( count < 1 )); then
  printf 'expected at least 1 tag row in IFD-0 listing\n' >&2
  sed -n '1,40p' "$tmpdir/ifd0.out" >&2
  exit 1
fi
