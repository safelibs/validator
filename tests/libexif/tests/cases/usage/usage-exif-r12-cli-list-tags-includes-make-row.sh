#!/usr/bin/env bash
# @testcase: usage-exif-r12-cli-list-tags-includes-make-row
# @title: exif --tag=Make --machine-readable emits the Make value for the canon fixture
# @description: Runs exif --tag=Make --machine-readable on the canon makernote fixture and asserts the output is non-empty and contains a printable Make value (the manufacturer name). (Noble's exif CLI does not implement --list-tags; the per-tag --machine-readable readback is the documented stable surface for verifying tag presence.)
# @timeout: 60
# @tags: usage, list-tags, make
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --tag=Make --machine-readable "$img" >"$tmpdir/out"
[[ -s "$tmpdir/out" ]] || { printf 'exif --tag=Make produced empty output\n' >&2; exit 1; }
# Output should contain a printable manufacturer name; reject empty/null lines.
grep -Eq '[A-Za-z]' "$tmpdir/out"
