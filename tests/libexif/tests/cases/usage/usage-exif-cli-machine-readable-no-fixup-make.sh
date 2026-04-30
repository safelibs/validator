#!/usr/bin/env bash
# @testcase: usage-exif-cli-machine-readable-no-fixup-make
# @title: exif --machine-readable --no-fixup combo emits Make
# @description: Combines --machine-readable with --no-fixup against the canon fixture and verifies the tab-delimited stream still reports the Manufacturer entry as Canon, that --tag=Make produces only Canon on its own line, and that the field-count and value match the plain --machine-readable run.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-machine-readable-no-fixup-make"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --no-fixup "$img" >"$tmpdir/combo.out"
exif --machine-readable "$img" >"$tmpdir/plain.out"

# Combo run must contain the Manufacturer/Canon tab pair
validator_assert_contains "$tmpdir/combo.out" $'Manufacturer\tCanon'
validator_assert_contains "$tmpdir/combo.out" $'Model\tCanon PowerShot S70'

# --no-fixup is documented but currently a no-op; both streams should match exactly
if ! cmp -s "$tmpdir/combo.out" "$tmpdir/plain.out"; then
  printf '--machine-readable --no-fixup output diverged from plain --machine-readable\n' >&2
  diff -u "$tmpdir/plain.out" "$tmpdir/combo.out" >&2 || true
  exit 1
fi

# Scoped --tag=Make readback must yield exactly Canon as the sole line
exif --machine-readable --no-fixup --tag=Make "$img" >"$tmpdir/make.out"
line_count=$(wc -l <"$tmpdir/make.out")
if (( line_count != 1 )); then
  printf 'expected exactly 1 line for --tag=Make machine-readable, got %d\n' "$line_count" >&2
  cat "$tmpdir/make.out" >&2
  exit 1
fi
read -r make_value <"$tmpdir/make.out"
if [[ "$make_value" != 'Canon' ]]; then
  printf 'expected machine-readable Make value Canon, got %q\n' "$make_value" >&2
  exit 1
fi
