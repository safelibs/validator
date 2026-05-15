#!/usr/bin/env bash
# @testcase: usage-exif-r20-cli-xml-output-yresolution-element
# @title: exif --xml-output emits a Y-Resolution element for the canon fixture
# @description: Runs exif --xml-output on the canon fixture and asserts the captured XML contains both an opening "<Y-Resolution>" tag and a closing "</Y-Resolution>" tag - locking in libexif's XML renderer including the Y-Resolution element with both delimiters.
# @timeout: 60
# @tags: usage, exif, xml-output, yresolution, r20
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --xml-output "$img" >"$tmpdir/out.xml" 2>"$tmpdir/err"
LC_ALL=C grep -Fq '<Y-Resolution>' "$tmpdir/out.xml" || {
    echo 'expected <Y-Resolution> opening tag in XML output' >&2
    head -c 4096 "$tmpdir/out.xml" >&2
    exit 1
}
LC_ALL=C grep -Fq '</Y-Resolution>' "$tmpdir/out.xml" || {
    echo 'expected </Y-Resolution> closing tag in XML output' >&2
    head -c 4096 "$tmpdir/out.xml" >&2
    exit 1
}
