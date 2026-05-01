#!/usr/bin/env bash
# @testcase: usage-gpg-symmetric-cast5-roundtrip
# @title: gpg CAST5 symmetric round trip
# @description: Symmetrically encrypts and decrypts with --cipher-algo CAST5 (allowed via --allow-old-cipher-algos) and confirms list-packets reports a symkey enc packet for the round-tripped ciphertext.
# @timeout: 180
# @tags: usage, gpg, crypto, encryption
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-symmetric-cast5-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-cast5-passphrase

printf 'cast5 symmetric payload\n' >"$tmpdir/plain.txt"
plain_sha=$(sha256sum "$tmpdir/plain.txt" | awk '{print $1}')

"${gpg_batch[@]}" --passphrase "$passphrase" --allow-old-cipher-algos \
  --cipher-algo CAST5 --symmetric -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
test -s "$tmpdir/plain.gpg"

"${gpg_batch[@]}" --passphrase "$passphrase" --decrypt \
  -o "$tmpdir/out.txt" "$tmpdir/plain.gpg"

out_sha=$(sha256sum "$tmpdir/out.txt" | awk '{print $1}')
test "$plain_sha" = "$out_sha"

"${gpg_batch[@]}" --passphrase "$passphrase" --list-packets "$tmpdir/plain.gpg" \
  >"$tmpdir/packets" 2>&1
validator_assert_contains "$tmpdir/packets" 'symkey enc packet'
