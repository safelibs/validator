#!/usr/bin/env bash
# @testcase: usage-gpg-symmetric-blowfish
# @title: gpg BLOWFISH symmetric round trip
# @description: Symmetrically encrypts and decrypts a payload with --cipher-algo BLOWFISH (allowed via --allow-old-cipher-algos) and verifies the plaintext is restored byte-for-byte.
# @timeout: 180
# @tags: usage, gpg, crypto, encryption
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-symmetric-blowfish"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-blowfish-passphrase

printf 'blowfish symmetric payload\n' >"$tmpdir/plain.txt"
plain_sha=$(sha256sum "$tmpdir/plain.txt" | awk '{print $1}')

"${gpg_batch[@]}" --passphrase "$passphrase" --allow-old-cipher-algos \
  --cipher-algo BLOWFISH --symmetric -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
test -s "$tmpdir/plain.gpg"

"${gpg_batch[@]}" --passphrase "$passphrase" --decrypt \
  -o "$tmpdir/out.txt" "$tmpdir/plain.gpg"

out_sha=$(sha256sum "$tmpdir/out.txt" | awk '{print $1}')
test "$plain_sha" = "$out_sha"
validator_assert_contains "$tmpdir/out.txt" 'blowfish symmetric payload'
