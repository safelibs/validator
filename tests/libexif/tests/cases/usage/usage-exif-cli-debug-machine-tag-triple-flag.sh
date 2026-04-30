#!/usr/bin/env bash
# @testcase: usage-exif-cli-debug-machine-tag-triple-flag
# @title: exif --debug --machine-readable --tag=Model triple-flag composition
# @description: Runs the exif client with the three flags --debug, --machine-readable, and --tag=Model combined against the canon fixture and verifies the loader trace lines reach stderr (or fall back to stdout) while the requested Model record still appears in machine-readable form on stdout, asserting that scoping with --tag does not suppress --debug diagnostics and that --debug does not corrupt single-tag --machine-readable output.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-debug-machine-tag-triple-flag"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --debug --machine-readable --tag=Model "$img" \
  >"$tmpdir/stdout" 2>"$tmpdir/stderr"

# Loader trace must be emitted somewhere (stderr preferred, stdout fallback).
cat "$tmpdir/stdout" "$tmpdir/stderr" >"$tmpdir/all"
validator_assert_contains "$tmpdir/all" 'ExifLoader: Scanning'
validator_assert_contains "$tmpdir/all" 'ExifData: Found EXIF header'

# The single requested tag must still surface in machine-readable form on stdout.
validator_assert_contains "$tmpdir/stdout" 'Canon PowerShot S70'

# The verbose 'Value:' prefix from text mode must NOT leak into stdout when
# --machine-readable is in effect.
if grep -Fq 'Value:' "$tmpdir/stdout"; then
  printf 'unexpected verbose Value: prefix in machine-readable triple-flag stdout\n' >&2
  cat "$tmpdir/stdout" >&2
  exit 1
fi

# The requested Model record must NOT have been swallowed by debug noise.
plain_model=$(exif --machine-readable --tag=Model "$img")
if [[ -z "$plain_model" ]]; then
  printf 'sanity check: plain --machine-readable --tag=Model produced no output\n' >&2
  exit 1
fi
if ! grep -Fq -- "$plain_model" "$tmpdir/stdout"; then
  printf 'expected the plain machine-readable Model record to appear in triple-flag stdout\n' >&2
  printf 'plain: %s\n' "$plain_model" >&2
  cat "$tmpdir/stdout" >&2
  exit 1
fi
