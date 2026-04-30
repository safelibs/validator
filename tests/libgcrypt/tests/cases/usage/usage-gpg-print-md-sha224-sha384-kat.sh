#!/usr/bin/env bash
# @testcase: usage-gpg-print-md-sha224-sha384-kat
# @title: gpg --print-md SHA224 and SHA384 KAT vectors
# @description: Computes SHA224 and SHA384 digests of the FIPS 180-4 vector "abc" with gpg --print-md and asserts byte-exact match against the published known-answer values.
# @timeout: 120
# @tags: usage, gpg, digest, kat
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-print-md-sha224-sha384-kat"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
export GNUPGHOME

# Expected KAT digests for FIPS 180-4 message "abc", lower-case, no whitespace.
exp_sha224='23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7'
exp_sha384='cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7'

# Feed the message via stdin so gpg --print-md does not prepend a filename:
# header. Output is uppercase hex with spaces; normalise to lower-case hex.
sha224_actual=$(printf 'abc' | gpg --print-md SHA224 | tr -d ' \t\r\n' | tr 'A-F' 'a-f')
sha384_actual=$(printf 'abc' | gpg --print-md SHA384 | tr -d ' \t\r\n' | tr 'A-F' 'a-f')

[[ "$sha224_actual" == "$exp_sha224" ]] || {
  printf 'SHA224 KAT mismatch:\n  expected %s\n  actual   %s\n' "$exp_sha224" "$sha224_actual" >&2
  exit 1
}
[[ "$sha384_actual" == "$exp_sha384" ]] || {
  printf 'SHA384 KAT mismatch:\n  expected %s\n  actual   %s\n' "$exp_sha384" "$sha384_actual" >&2
  exit 1
}
