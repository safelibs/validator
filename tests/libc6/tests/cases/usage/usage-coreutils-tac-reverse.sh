#!/usr/bin/env bash
# @testcase: usage-coreutils-tac-reverse
# @title: coreutils tac reverses line order
# @description: Reverses a five-line input file with tac and verifies both the line order and total line count.
# @timeout: 180
# @tags: usage, coreutils, text
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-tac-reverse"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'one\ntwo\nthree\nfour\nfive\n' >"$tmpdir/in.txt"

tac "$tmpdir/in.txt" >"$tmpdir/out"

expected=$(printf 'five\nfour\nthree\ntwo\none\n')
actual=$(cat "$tmpdir/out")
if [[ "$actual" != "$expected" ]]; then
  printf 'tac reversed output mismatch:\n%s\n' "$actual" >&2
  exit 1
fi

line_count=$(wc -l <"$tmpdir/out")
if (( line_count != 5 )); then
  printf 'tac line count mismatch: %s\n' "$line_count" >&2
  exit 1
fi
