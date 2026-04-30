#!/usr/bin/env bash
# @testcase: usage-exif-cli-tag-compression-machine-cross-check
# @title: exif --tag=Compression cross-checks human and machine-readable JPEG mode
# @description: Reads the Compression tag with the exif client in both default text mode and --machine-readable mode against the canon fixture, asserts the human-readable form contains the JPEG compression label while the machine-readable form is the bare JPEG compression record, and asserts the two outputs differ so the formatting modes really are independent.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-tag-compression-machine-cross-check"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

# Default text-mode --tag=Compression: verbose record with descriptive label
exif --tag=Compression "$img" >"$tmpdir/text.out"
validator_assert_contains "$tmpdir/text.out" 'JPEG compression'
validator_assert_contains "$tmpdir/text.out" 'Value:'

# --machine-readable --tag=Compression: bare line, still contains the literal value
exif --machine-readable --tag=Compression "$img" >"$tmpdir/machine.out"
validator_assert_contains "$tmpdir/machine.out" 'JPEG compression'

# Sanity: the machine-readable form must not include the verbose 'Value:' prefix
if grep -Fq 'Value:' "$tmpdir/machine.out"; then
  printf 'unexpected verbose Value: prefix in --machine-readable output\n' >&2
  cat "$tmpdir/machine.out" >&2
  exit 1
fi

# The two outputs must be byte-different (proves both formats are wired up).
if cmp -s "$tmpdir/text.out" "$tmpdir/machine.out"; then
  printf 'text and machine-readable Compression outputs were unexpectedly identical\n' >&2
  cat "$tmpdir/text.out" >&2
  exit 1
fi
