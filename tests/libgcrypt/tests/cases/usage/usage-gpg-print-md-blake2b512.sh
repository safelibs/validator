#!/usr/bin/env bash
# @testcase: usage-gpg-print-md-blake2b512
# @title: gpg print-md outputs full BLAKE2b-512 digest
# @description: Computes a BLAKE2B512 digest using gpg --with-colons --print-md and asserts the output is a 128 hex character digest line.
# @timeout: 180
# @tags: usage, gpg, digest
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-print-md-blake2b512"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

# Empty input: gpg should still emit the BLAKE2b-512 digest of zero bytes.
: >"$tmpdir/empty.bin"
gpg --with-colons --print-md BLAKE2B512 "$tmpdir/empty.bin" >"$tmpdir/out"
hex=$(grep -Eo '[0-9A-F]{128}' "$tmpdir/out" | head -n 1)
test -n "$hex"
test ${#hex} -eq 128
