#!/usr/bin/env bash
# @testcase: usage-coreutils-tr-complement-keep
# @title: coreutils tr complement-delete keeps alnum
# @description: Filters a noisy string with tr -dc to keep only alphanumeric bytes and verifies the resulting payload exactly.
# @timeout: 180
# @tags: usage, coreutils, text
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-tr-complement-keep"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'Hello, World! 2026 -- the quick (brown) fox.' >"$tmpdir/in.txt"

tr -dc 'A-Za-z0-9' <"$tmpdir/in.txt" >"$tmpdir/out"

actual=$(cat "$tmpdir/out")
expected='HelloWorld2026thequickbrownfox'
if [[ "$actual" != "$expected" ]]; then
  printf 'tr -dc output mismatch:\n actual:   %s\n expected: %s\n' "$actual" "$expected" >&2
  exit 1
fi

byte_count=$(wc -c <"$tmpdir/out")
if (( byte_count != ${#expected} )); then
  printf 'tr -dc byte count mismatch: %s vs %s\n' "$byte_count" "${#expected}" >&2
  exit 1
fi
