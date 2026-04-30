#!/usr/bin/env bash
# @testcase: usage-gpg-list-packets-symmetric-twofish
# @title: gpg list-packets on TWOFISH symmetric ciphertext
# @description: Symmetrically encrypts with TWOFISH and verifies gpg --list-packets reports the expected encrypted packet description.
# @timeout: 180
# @tags: usage, gpg, metadata
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-list-packets-symmetric-twofish"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-twofish-packets

printf 'twofish packet listing payload\n' >"$tmpdir/plain.txt"

"${gpg_batch[@]}" --passphrase "$passphrase" --cipher-algo TWOFISH \
  --symmetric -o "$tmpdir/cipher.gpg" "$tmpdir/plain.txt"

"${gpg_batch[@]}" --passphrase "$passphrase" \
  --list-packets "$tmpdir/cipher.gpg" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'encrypted data packet'
validator_assert_contains "$tmpdir/out" 'symkey enc packet'
