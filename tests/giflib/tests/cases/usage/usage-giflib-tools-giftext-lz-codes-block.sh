#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftext-lz-codes-block
# @title: giftext -z dumps decompressed LZW code rows for every image
# @description: Runs giftext -z on fire.gif and verifies the output contains a substantial number of decompressed-code offset rows (matching ^[0-9a-f]+: with three-digit code tokens) and ends with the standard "GIF file terminated normally." sentinel, exercising the -z decompressed-code dump mode that is otherwise uncovered.
# @timeout: 60
# @tags: usage, cli, giftext, lz
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftext -z "$gif" >"$tmpdir/lz.txt"

# Offset rows look like "00000: 100 0e5 102 103 ..." (three-digit hex codes).
code_rows=$(grep -cE '^[0-9a-f]+: [0-9a-f]{3}( [0-9a-f]{3})+' "$tmpdir/lz.txt" || true)
if (( code_rows < 50 )); then
  printf 'expected substantial decompressed-code dump, got %s rows\n' "$code_rows" >&2
  sed -n '1,40p' "$tmpdir/lz.txt" >&2
  exit 1
fi

# At least one "Image #N:" header should still appear in the listing.
if ! grep -qE '^Image #[0-9]+:' "$tmpdir/lz.txt"; then
  printf '-z output contained no Image #N records\n' >&2
  exit 1
fi

# Final non-empty line must be the trailer.
last_nonblank=$(awk 'NF { line=$0 } END { print line }' "$tmpdir/lz.txt")
if [[ "$last_nonblank" != "GIF file terminated normally." ]]; then
  printf 'expected trailer "GIF file terminated normally.", got %q\n' \
    "$last_nonblank" >&2
  tail -n 5 "$tmpdir/lz.txt" >&2
  exit 1
fi
