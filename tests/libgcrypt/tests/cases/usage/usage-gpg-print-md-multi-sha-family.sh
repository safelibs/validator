#!/usr/bin/env bash
# @testcase: usage-gpg-print-md-multi-sha-family
# @title: gpg --print-md multi-algorithm digest lengths
# @description: Computes SHA1, SHA224, SHA256, SHA384, and SHA512 digests of the same input via gpg --with-colons --print-md and asserts each output line contains a hex digest of the expected length for its algorithm.
# @timeout: 180
# @tags: usage, gpg, digest
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-print-md-multi-sha-family"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'multi sha family payload\n' >"$tmpdir/plain.txt"

assert_hex_len() {
  local algo=$1
  local expected_len=$2
  local out="$tmpdir/${algo}.out"
  gpg --with-colons --print-md "$algo" "$tmpdir/plain.txt" >"$out"
  local hex
  hex=$(grep -Eo '[0-9A-F]+' "$out" | awk -v n="$expected_len" 'length($0)==n {print; exit}')
  test -n "$hex" || {
    printf '%s: missing %d-hex digest\n' "$algo" "$expected_len" >&2
    cat "$out" >&2
    exit 1
  }
  test "${#hex}" -eq "$expected_len"
}

assert_hex_len SHA1 40
assert_hex_len SHA224 56
assert_hex_len SHA256 64
assert_hex_len SHA384 96
assert_hex_len SHA512 128
