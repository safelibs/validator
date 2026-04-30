#!/usr/bin/env bash
# @testcase: usage-gpg-print-md-sha3-256-kat-abc
# @title: gpg print-md SHA3-256 KAT for "abc"
# @description: Computes the SHA3-256 digest of the literal byte string "abc" through gpg --print-md and asserts the canonical FIPS 202 known-answer value.
# @timeout: 120
# @tags: usage, gpg, digest, kat
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-print-md-sha3-256-kat-abc"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)

# FIPS 202 / NIST CSRC published vector: SHA3-256("abc")
expected="3A985DA74FE225B2045C172D6BD390BD855F086E3E9D525B46BFE24511431532"

printf 'abc' >"$tmpdir/abc"
"${gpg_batch[@]}" --print-md SHA3-256 "$tmpdir/abc" >"$tmpdir/raw"

# Output is "<path>: HEX HEX ..."; collapse to a contiguous uppercase hex string.
hex=$(awk -F: 'NR==1 {sub(/^ +/, "", $2); print $2; next} {print}' "$tmpdir/raw" \
  | tr -d ' \t\n')
printf '%s' "$hex" | grep -qE '^[0-9A-F]{64}$' || {
  printf 'sha3-256 output is not 64 hex chars: %s\n' "$hex" >&2
  exit 1
}

if [[ "$hex" != "$expected" ]]; then
  printf 'sha3-256 KAT mismatch:\n  got:      %s\n  expected: %s\n' "$hex" "$expected" >&2
  exit 1
fi
