#!/usr/bin/env bash
# @testcase: usage-exif-r12-cli-show-mnote-machine-readable-not-empty
# @title: exif --show-mnote --machine-readable emits at least one tab-delimited record per MakerNote entry
# @description: Runs --show-mnote in machine-readable mode and verifies the output is non-empty and every line contains at least one tab character, confirming libexif emits the per-entry tab-separated record format the CLI documents for the makernote dump.
# @timeout: 60
# @tags: usage, mnote, machine-readable
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --show-mnote --machine-readable "$img" >"$tmpdir/out"

lines=$(wc -l <"$tmpdir/out")
if (( lines < 1 )); then
  echo "no mnote lines emitted" >&2
  exit 1
fi

# Every line must contain at least one tab.
if grep -vP '\t' "$tmpdir/out" >/dev/null; then
  echo "found non-tabbed line in machine-readable mnote output" >&2
  grep -vP '\t' "$tmpdir/out" | head >&2
  exit 1
fi
