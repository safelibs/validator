#!/usr/bin/env bash
# @testcase: usage-exif-cli-machine-tag-exposure-time
# @title: exif --machine-readable --tag=ExposureTime emits 1 sec.
# @description: Runs the exif client with --machine-readable --tag=ExposureTime against the canon fixture and verifies the scoped run emits exactly one line carrying the 1 sec. value, while a parallel scan of the unscoped --machine-readable stream confirms the same value is reachable when filtered for the Exposure Time row.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-machine-tag-exposure-time"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

# Scoped run: must yield exactly one line with the 1 sec. payload
exif --machine-readable --tag=ExposureTime "$img" >"$tmpdir/scoped.out"
line_count=$(wc -l <"$tmpdir/scoped.out")
if (( line_count != 1 )); then
  printf 'expected 1 line for --tag=ExposureTime --machine-readable, got %d\n' "$line_count" >&2
  cat "$tmpdir/scoped.out" >&2
  exit 1
fi
read -r scoped_value <"$tmpdir/scoped.out"
if [[ "$scoped_value" != '1 sec.' ]]; then
  printf 'expected scoped machine-readable value "1 sec.", got %q\n' "$scoped_value" >&2
  exit 1
fi

# Unscoped run: the Exposure Time row must surface the same value
exif --machine-readable "$img" >"$tmpdir/full.out"
unscoped_value=$(awk -F '\t' '$1 == "Exposure Time" { print $2; exit }' "$tmpdir/full.out")
if [[ "$unscoped_value" != '1 sec.' ]]; then
  printf 'expected unscoped Exposure Time row "1 sec.", got %q\n' "$unscoped_value" >&2
  cat "$tmpdir/full.out" >&2
  exit 1
fi
