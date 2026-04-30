#!/usr/bin/env bash
# @testcase: usage-exif-cli-machine-key-value-shell-parse
# @title: exif --machine-readable parses into shell key=value pairs
# @description: Runs the exif client with --machine-readable and pipes the tab-delimited stream through awk to produce a key=value file, then verifies that programmatic lookups for Manufacturer, Model, Color Space, and Exif Version recover the expected literal values.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-machine-key-value-shell-parse"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable "$img" >"$tmpdir/raw"

# Convert tab-separated key/value rows into key=value lines for shell consumption
awk -F '\t' 'NF>=2 {
  key=$1
  val=$2
  for (i=3; i<=NF; i++) val = val "\t" $i
  printf "%s=%s\n", key, val
}' "$tmpdir/raw" >"$tmpdir/kv"

lookup() {
  local key=$1
  awk -F= -v k="$key" 'index($0, k"=")==1 {sub(/^[^=]*=/, ""); print; exit}' "$tmpdir/kv"
}

manufacturer=$(lookup 'Manufacturer')
model=$(lookup 'Model')
color=$(lookup 'Color Space')
exver=$(lookup 'Exif Version')

if [[ "$manufacturer" != 'Canon' ]]; then
  printf 'unexpected Manufacturer parse: %q\n' "$manufacturer" >&2
  exit 1
fi
if [[ "$model" != 'Canon PowerShot S70' ]]; then
  printf 'unexpected Model parse: %q\n' "$model" >&2
  exit 1
fi
if [[ "$color" != 'sRGB' ]]; then
  printf 'unexpected Color Space parse: %q\n' "$color" >&2
  exit 1
fi
if [[ "$exver" != 'Exif Version 2.2' ]]; then
  printf 'unexpected Exif Version parse: %q\n' "$exver" >&2
  exit 1
fi
