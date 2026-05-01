#!/usr/bin/env bash
# @testcase: usage-gpg-print-md-sha3-512-hex
# @title: gpg print-md SHA3-512 with hex output
# @description: Computes a SHA3-512 digest with gpg --print-md --with-colons and confirms the output is a continuous 128 hex character digest line.
# @timeout: 180
# @tags: usage, gpg, digest
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-print-md-sha3-512-hex"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'sha3-512 colon payload\n' >"$tmpdir/plain.txt"
gpg --with-colons --print-md SHA3-512 "$tmpdir/plain.txt" >"$tmpdir/out"
# colon mode prints uppercase hex without separators
hex=$(grep -Eo '[0-9A-F]{128}' "$tmpdir/out" | head -n 1)
test -n "$hex"
test ${#hex} -eq 128
