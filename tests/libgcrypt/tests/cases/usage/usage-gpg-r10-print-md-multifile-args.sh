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

# gpg formats SHA256 as eight 8-hex groups across two lines per file;
# verify >= 16 such groups (8 per digest * 2 files) appear.
groups=$(grep -oE '\b[0-9A-F]{8}\b' "$tmpdir/out" | wc -l)
[[ "$groups" -ge 16 ]] || {
  printf 'expected >=16 8-hex groups (2 sha256 digests), got %s\n' "$groups" >&2
  cat "$tmpdir/out" >&2
  exit 1
}
