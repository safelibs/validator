#!/usr/bin/env bash
# @testcase: usage-exif-cli-invalid-tag-name-error
# @title: exif --tag rejects an unknown tag name
# @description: Runs exif --tag=NotARealTag against the canon fixture and verifies the client exits non-zero and prints the canonical "Invalid tag" diagnostic naming the bogus token. Pins libexif's argp-side validation of --tag values on Ubuntu 24.04 against accidental client typos.
# @timeout: 60
# @tags: usage, metadata, error
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-invalid-tag-name-error"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

set +e
exif --tag=NotARealTag "$img" >"$tmpdir/stdout" 2>"$tmpdir/stderr"
rc=$?
set -e

if (( rc == 0 )); then
  printf 'expected non-zero exit on invalid tag name, got rc=0\n' >&2
  cat "$tmpdir/stdout" "$tmpdir/stderr" >&2
  exit 1
fi

cat "$tmpdir/stdout" "$tmpdir/stderr" >"$tmpdir/all"
validator_assert_contains "$tmpdir/all" 'Invalid tag'
validator_assert_contains "$tmpdir/all" 'NotARealTag'
