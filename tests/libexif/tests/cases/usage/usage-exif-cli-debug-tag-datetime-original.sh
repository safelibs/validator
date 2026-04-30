#!/usr/bin/env bash
# @testcase: usage-exif-cli-debug-tag-datetime-original
# @title: exif --debug --tag=DateTimeOriginal preserves the scoped readout
# @description: Runs the exif client with the combined --debug and --tag=DateTimeOriginal flags against the canon fixture and verifies the loader trace reaches the combined output stream while the scoped pretty-print still surfaces the DateTimeOriginal Value line carrying the literal 2009:10:10 16:42:32 timestamp. The combined output is also compared against a clean (non-debug) scoped run to confirm --debug does not drop or rewrite the scoped Value line.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-debug-tag-datetime-original"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --debug --tag=DateTimeOriginal "$img" >"$tmpdir/stdout" 2>"$tmpdir/stderr"
cat "$tmpdir/stdout" "$tmpdir/stderr" >"$tmpdir/all"

# Loader trace must appear somewhere in the combined output
validator_assert_contains "$tmpdir/all" 'ExifLoader: Scanning'
validator_assert_contains "$tmpdir/all" 'ExifData: Found EXIF header'

# Scoped readout must still carry the DateTimeOriginal Value line with the
# canon fixture's literal timestamp.
validator_assert_contains "$tmpdir/all" 'Value:'
validator_assert_contains "$tmpdir/all" '2009:10:10 16:42:32'

# Sanity: a clean scoped run must agree on the literal timestamp.
exif --tag=DateTimeOriginal "$img" >"$tmpdir/plain.out"
validator_assert_contains "$tmpdir/plain.out" '2009:10:10 16:42:32'
