#!/usr/bin/env bash
# @testcase: usage-gpg-symmetric-empty-input
# @title: gpg symmetric encrypts zero-byte input
# @description: Encrypts a zero-byte plaintext with AES256 symmetric mode and decrypts it, asserting the round-tripped output is also zero bytes.
# @timeout: 180
# @tags: usage, gpg, crypto, edgecase
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-symmetric-empty-input"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-empty-passphrase

: >"$tmpdir/plain.bin"
test "$(wc -c <"$tmpdir/plain.bin")" -eq 0

"${gpg_batch[@]}" --passphrase "$passphrase" --cipher-algo AES256 \
  --symmetric -o "$tmpdir/plain.gpg" "$tmpdir/plain.bin"
test -s "$tmpdir/plain.gpg"

"${gpg_batch[@]}" --passphrase "$passphrase" --decrypt \
  -o "$tmpdir/out.bin" "$tmpdir/plain.gpg"
test "$(wc -c <"$tmpdir/out.bin")" -eq 0
