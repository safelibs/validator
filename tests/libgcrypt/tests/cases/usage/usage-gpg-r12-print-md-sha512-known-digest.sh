#!/usr/bin/env bash
# @testcase: usage-gpg-r12-print-md-sha512-known-digest
# @title: gpg --print-md SHA512 of "abc" matches the known canonical digest
# @description: Writes the bytes "abc" to a file and runs gpg --print-md SHA512, then strips formatting and verifies the digest equals the canonical SHA-512 of "abc" published in FIPS 180-4.
# @timeout: 60
# @tags: usage, gpg, digest, sha512
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'abc' >"$tmpdir/in.bin"

gpg --print-md SHA512 "$tmpdir/in.bin" >"$tmpdir/out" 2>"$tmpdir/err" || true

# SHA-512 wraps across multiple lines: file header on line 1, then
# leading-whitespace continuation lines with more hex groups. Collect the
# header's hex tail, then concatenate every leading-whitespace hex
# continuation that follows.
digest=$(awk -v f="$tmpdir/in.bin" '
    BEGIN { found = 0 }
    /^gpg:/ { next }
    !found && index($0, f) == 1 {
        sub(/^[^:]*:[[:space:]]*/, "")
        printf "%s", $0
        found = 1
        next
    }
    found && /^[[:space:]]+[0-9A-Fa-f]/ {
        printf "%s", $0
    }
' "$tmpdir/out" | tr -d ' \t\n' | tr 'A-Z' 'a-z')
expected='ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f'
[[ "$digest" == "$expected" ]] || {
  printf 'sha512 mismatch: got=%s expected=%s\n' "$digest" "$expected" >&2
  cat "$tmpdir/out" >&2
  exit 1
}
