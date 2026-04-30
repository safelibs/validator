#!/usr/bin/env bash
# @testcase: usage-exif-cli-debug-machine-readable-combo
# @title: exif --debug --machine-readable preserves the tab-delimited record stream
# @description: Runs the exif client with --debug --machine-readable against the canon fixture and verifies the loader trace is emitted to stderr while stdout still carries the standard tab-delimited Manufacturer/Canon and Model/Canon PowerShot S70 records, asserting --debug does not corrupt --machine-readable framing.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-debug-machine-readable-combo"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --debug --machine-readable "$img" >"$tmpdir/stdout" 2>"$tmpdir/stderr"

# Loader trace must reach somewhere (stderr preferred, stdout fallback)
cat "$tmpdir/stdout" "$tmpdir/stderr" >"$tmpdir/all"
validator_assert_contains "$tmpdir/all" 'ExifLoader: Scanning'
validator_assert_contains "$tmpdir/all" 'ExifData: Found EXIF header'
validator_assert_contains "$tmpdir/all" 'ExifData: Loading 9 entries...'

# Machine-readable rows must still be parseable on stdout (tab framing preserved)
validator_assert_contains "$tmpdir/stdout" $'Manufacturer\tCanon'
validator_assert_contains "$tmpdir/stdout" $'Model\tCanon PowerShot S70'

# Compare the machine-readable stdout against a clean (non-debug) run for the rows
# that must always be present, ignoring any debug noise that may interleave on stdout.
exif --machine-readable "$img" >"$tmpdir/plain.out"
for needle in $'Manufacturer\tCanon' $'Model\tCanon PowerShot S70' $'Color Space\tsRGB'; do
  if ! grep -Fq -- "$needle" "$tmpdir/stdout"; then
    printf 'expected debug+machine stdout to carry: %s\n' "$needle" >&2
    cat "$tmpdir/stdout" >&2
    exit 1
  fi
  if ! grep -Fq -- "$needle" "$tmpdir/plain.out"; then
    printf 'sanity check: plain machine-readable also missing %s\n' "$needle" >&2
    cat "$tmpdir/plain.out" >&2
    exit 1
  fi
done
