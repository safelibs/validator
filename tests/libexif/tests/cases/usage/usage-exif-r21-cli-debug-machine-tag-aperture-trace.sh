#!/usr/bin/env bash
# @testcase: usage-exif-r21-cli-debug-machine-tag-aperture-trace
# @title: exif --debug --machine-readable --tag=ApertureValue emits parser trace and value line
# @description: Runs exif --debug --machine-readable --tag=ApertureValue --ifd=EXIF on the Canon fixture with merged stdout+stderr, asserts the captured output contains the libexif debug markers "ExifLoader:" and "ExifData:" indicating parser tracing, and also contains a final machine-readable APEX value matching the "f/" aperture marker - locking in the simultaneous emission of debug trace and machine-readable result.
# @timeout: 60
# @tags: usage, exif, debug, aperture, r21
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --debug --machine-readable --tag=ApertureValue --ifd=EXIF "$img" >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" 'ExifLoader:'
validator_assert_contains "$tmpdir/out" 'ExifData:'
validator_assert_contains "$tmpdir/out" 'f/'
