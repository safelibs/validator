#!/usr/bin/env bash
# @testcase: usage-exif-r17-cli-default-output-mentions-canon
# @title: exif default pretty-print on canon fixture mentions Canon manufacturer
# @description: Runs exif (no flags) on the canon fixture and asserts exit==0 and the pretty-printed output contains the substring "Canon" (the manufacturer string), exercising libexif's default text dump including IFD0 Make.
# @timeout: 60
# @tags: usage, exif, default-output
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif "$img" >"$tmpdir/out" 2>"$tmpdir/err"
validator_assert_contains "$tmpdir/out" 'Canon'
