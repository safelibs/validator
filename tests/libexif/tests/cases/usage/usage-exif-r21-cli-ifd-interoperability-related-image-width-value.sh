#!/usr/bin/env bash
# @testcase: usage-exif-r21-cli-ifd-interoperability-related-image-width-value
# @title: exif --ifd=Interoperability lists RelatedImageWidth 640 on the canon fixture
# @description: Runs exif --ifd=Interoperability on the Canon fixture, asserts the captured listing contains "RelatedImageWidth" alongside the value 640 - locking in libexif's handling of the Interoperability IFD as a distinct IFD with content reachable via --ifd=Interoperability.
# @timeout: 60
# @tags: usage, exif, ifd, interoperability, r21
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ifd=Interoperability "$img" >"$tmpdir/out" 2>"$tmpdir/err"
validator_assert_contains "$tmpdir/out" 'RelatedImageWidth'
LC_ALL=C grep -E 'RelatedImageWidth[^0-9]*640' "$tmpdir/out" >/dev/null || {
    echo 'expected RelatedImageWidth row with value 640' >&2
    cat "$tmpdir/out" >&2
    exit 1
}
