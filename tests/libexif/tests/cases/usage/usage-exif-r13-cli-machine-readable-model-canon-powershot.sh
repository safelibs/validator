#!/usr/bin/env bash
# @testcase: usage-exif-r13-cli-machine-readable-model-canon-powershot
# @title: exif --machine-readable --tag=Model emits exactly "Canon PowerShot S70"
# @description: Reads the Model tag in --machine-readable mode and verifies the output is exactly the literal string "Canon PowerShot S70" plus a single newline with line count == 1, asserting libexif emits the bare ASCII value without annotation in machine-readable mode.
# @timeout: 60
# @tags: usage, machine-readable, model
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --tag=Model "$img" >"$tmpdir/out"
read -r value <"$tmpdir/out"
if [[ "$value" != "Canon PowerShot S70" ]]; then
  printf 'expected Model="Canon PowerShot S70", got: %s\n' "$value" >&2
  exit 1
fi

lines=$(wc -l <"$tmpdir/out")
if (( lines != 1 )); then
  printf 'expected exactly 1 line, got %d\n' "$lines" >&2
  exit 1
fi
