#!/usr/bin/env bash
# @testcase: usage-exif-r21-cli-no-fixup-missing-tag-error
# @title: exif --no-fixup --tag=DateTime --ifd=EXIF reports missing-tag with nonzero exit
# @description: Runs exif --no-fixup --machine-readable --tag=DateTime --ifd=EXIF on the Canon fixture - DateTime lives in IFD0 and without fixup it is not present in the EXIF IFD - and asserts the command exits nonzero with stderr or stdout containing "does not contain tag" and "DateTime", locking in libexif's negative-path output when --no-fixup is requested.
# @timeout: 60
# @tags: usage, exif, no-fixup, missing-tag, r21
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

set +e
exif --no-fixup --machine-readable --tag=DateTime --ifd=EXIF "$img" \
    >"$tmpdir/out" 2>"$tmpdir/err"
rc=$?
set -e
[[ $rc -ne 0 ]] || { echo 'expected non-zero exit, got 0' >&2; cat "$tmpdir/out" "$tmpdir/err" >&2; exit 1; }
cat "$tmpdir/out" "$tmpdir/err" >"$tmpdir/all"
validator_assert_contains "$tmpdir/all" 'does not contain tag'
validator_assert_contains "$tmpdir/all" 'DateTime'
