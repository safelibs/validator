#!/usr/bin/env bash
# @testcase: usage-gpg-print-md-sha3-512-kat
# @title: gpg --print-md SHA3-512 KAT vector
# @description: Computes the SHA3-512 digest of the FIPS 202 message "abc" via gpg --print-md and asserts a byte-exact match against the published known-answer value.
# @timeout: 120
# @tags: usage, gpg, digest, kat
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-print-md-sha3-512-kat"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
export GNUPGHOME

# FIPS 202 SHA3-512 KAT for the message "abc" (no trailing newline).
exp_sha3_512='b751850b1a57168a5693cd924b6b096e08f621827444f70d884f5d0240d2712e10e116e9192af3c91a7ec57647e3934057340b4cf408d5a56592f8274eec53f0'

# Feed the message via stdin so gpg --print-md does not prepend a "filename:"
# header. Output is uppercase hex with spaces; normalise to lower-case hex.
actual=$(printf 'abc' | gpg --print-md SHA3-512 | tr -d ' \t\r\n' | tr 'A-F' 'a-f')

[[ "$actual" == "$exp_sha3_512" ]] || {
  printf 'SHA3-512 KAT mismatch:\n  expected %s\n  actual   %s\n' "$exp_sha3_512" "$actual" >&2
  exit 1
}
