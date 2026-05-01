#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftext-grid-single-image-record
# @title: giftext emits exactly one Image #N header for gifgrid.gif
# @description: Runs giftext on the single-frame gifgrid.gif and asserts there is exactly one Image #N record (with N starting at 1) on stdout, anchoring the headerless single-image case alongside the existing fire.gif multi-frame coverage.
# @timeout: 60
# @tags: usage, cli, giftext
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/gifgrid.gif"
validator_require_file "$gif"

giftext "$gif" >"$tmpdir/info.txt"

grep -E '^Image #[0-9]+:' "$tmpdir/info.txt" >"$tmpdir/headers.txt" || true
count=$(wc -l <"$tmpdir/headers.txt")
[[ "$count" -eq 1 ]] || {
  printf 'expected exactly 1 Image # header for gifgrid, got %s\n' "$count" >&2
  cat "$tmpdir/headers.txt" >&2
  exit 1
}

first_idx=$(sed -n 's/^Image #\([0-9]\+\):.*/\1/p' "$tmpdir/headers.txt" | head -n 1)
[[ "$first_idx" == "1" ]] || {
  printf 'expected first image header index 1, got %s\n' "$first_idx" >&2
  exit 1
}
