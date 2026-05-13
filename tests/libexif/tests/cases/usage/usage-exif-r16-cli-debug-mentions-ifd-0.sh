#!/usr/bin/env bash
# @testcase: usage-exif-r16-cli-debug-mentions-ifd-0
# @title: exif --debug log mentions the IFD 0 marker for the canon fixture
# @description: Runs exif --debug against the canon fixture, captures combined stdout/stderr, and asserts the trace mentions "IFD '0'" (libexif's debug logger prints quoted IFD names as it parses each directory), confirming the debug code path is engaged for IFD 0.
# @timeout: 60
# @tags: usage, debug, ifd-0
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --debug "$img" >"$tmpdir/out" 2>"$tmpdir/err" || true

combined="$tmpdir/combined"
cat "$tmpdir/out" "$tmpdir/err" >"$combined"
validator_assert_contains "$combined" "IFD '0'"
