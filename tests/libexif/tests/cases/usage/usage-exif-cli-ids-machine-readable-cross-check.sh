#!/usr/bin/env bash
# @testcase: usage-exif-cli-ids-machine-readable-cross-check
# @title: exif --ids --machine-readable cross-check
# @description: Runs the exif client with --ids --machine-readable on the canon fixture, parses the tab-delimited stream, and cross-checks the value column for tag id 0x0112 (Orientation) against the corresponding plain --machine-readable lookup to confirm both modes report identical Right-top text.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-ids-machine-readable-cross-check"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --ids --machine-readable "$img" >"$tmpdir/ids.out"
exif --machine-readable "$img" >"$tmpdir/named.out"

# --machine-readable always reports the Right-top Orientation value as a tab-row
if ! grep -E $'^Orientation\t' "$tmpdir/named.out" >"$tmpdir/named.orientation"; then
  printf 'expected Orientation row in --machine-readable stream\n' >&2
  cat "$tmpdir/named.out" >&2
  exit 1
fi
validator_assert_contains "$tmpdir/named.orientation" 'Right-top'

# The Right-top value must also appear in the --ids --machine-readable stream
validator_assert_contains "$tmpdir/ids.out" 'Right-top'
validator_assert_contains "$tmpdir/ids.out" 'Canon'

# Both streams must have the same number of rows since --ids should only swap key labels
ids_rows=$(wc -l <"$tmpdir/ids.out")
named_rows=$(wc -l <"$tmpdir/named.out")
if (( ids_rows != named_rows )); then
  printf 'row count mismatch: ids=%d named=%d\n' "$ids_rows" "$named_rows" >&2
  exit 1
fi

# The set of value columns (column 2 onward) must match between the two streams,
# so each Orientation/Manufacturer/etc. record is preserved across the rename.
awk -F '\t' '{$1=""; sub(/^\t/, ""); print}' "$tmpdir/ids.out" | sort >"$tmpdir/ids.values"
awk -F '\t' '{$1=""; sub(/^\t/, ""); print}' "$tmpdir/named.out" | sort >"$tmpdir/named.values"
if ! cmp -s "$tmpdir/ids.values" "$tmpdir/named.values"; then
  printf 'value columns diverge between --ids and named --machine-readable streams\n' >&2
  diff -u "$tmpdir/named.values" "$tmpdir/ids.values" >&2 || true
  exit 1
fi
