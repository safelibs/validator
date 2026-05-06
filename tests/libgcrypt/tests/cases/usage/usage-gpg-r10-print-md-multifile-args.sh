#!/usr/bin/env bash
# @testcase: usage-gpg-r10-print-md-multifile-args
# @title: gpg --print-md SHA256 over multiple file arguments
# @description: Invokes gpg --print-md SHA256 with two distinct file arguments in one call and verifies each file's name appears with a 64-character hex digest in the output.
# @timeout: 60
# @tags: usage, gpg, digest
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'alpha-content\n' >"$tmpdir/a.txt"
printf 'beta-content\n'  >"$tmpdir/b.txt"

gpg --print-md SHA256 "$tmpdir/a.txt" "$tmpdir/b.txt" >"$tmpdir/out" 2>&1

validator_assert_contains "$tmpdir/out" 'a.txt:'
validator_assert_contains "$tmpdir/out" 'b.txt:'

# Two distinct 64-hex digests (SHA-256) should appear (whitespace allowed within hex).
hex_lines=$(grep -cE '([0-9A-F]{2}[[:space:]]*){32}' "$tmpdir/out")
[[ "$hex_lines" -ge 2 ]] || {
  printf 'expected >=2 sha256 hex digests, found %s\n' "$hex_lines" >&2
  cat "$tmpdir/out" >&2
  exit 1
}
