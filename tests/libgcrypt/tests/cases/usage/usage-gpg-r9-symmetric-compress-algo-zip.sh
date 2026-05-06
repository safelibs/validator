#!/usr/bin/env bash
# @testcase: usage-gpg-r9-symmetric-compress-algo-zip
# @title: gpg symmetric with --compress-algo zip
# @description: Symmetrically encrypts a file with --compress-algo zip and decrypts the result, verifying the plaintext roundtrip succeeds.
# @timeout: 120
# @tags: usage, gpg, symmetric, compression
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'compress-algo-zip-payload\n' >"$tmpdir/plain.txt"
gpg --batch --yes --pinentry-mode loopback --passphrase 'pp' \
  --compress-algo zip --symmetric -o "$tmpdir/cipher.gpg" "$tmpdir/plain.txt"
[[ -s "$tmpdir/cipher.gpg" ]]

gpg --batch --yes --pinentry-mode loopback --passphrase 'pp' \
  -d "$tmpdir/cipher.gpg" >"$tmpdir/out" 2>/dev/null
validator_assert_contains "$tmpdir/out" 'compress-algo-zip-payload'
