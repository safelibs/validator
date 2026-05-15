#!/usr/bin/env bash
# @testcase: usage-exif-r19-cli-debug-no-fixup-trace-contains-loader
# @title: exif --debug --no-fixup trace contains the ExifLoader: Scanning header
# @description: Runs exif --debug --no-fixup against the canon fixture, merging stdout and stderr, and asserts the captured trace contains the literal "ExifLoader: Scanning" header (libexif emits the loader announce line even when fixups are disabled), exercising the libexif debug-trace path with --no-fixup active.
# @timeout: 60
# @tags: usage, exif, debug, loader, no-fixup, r19
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --debug --no-fixup "$img" >"$tmpdir/log" 2>&1 || true

validator_assert_contains "$tmpdir/log" 'ExifLoader: Scanning'
