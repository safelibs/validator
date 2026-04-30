#!/usr/bin/env bash
# @testcase: usage-gpg-symmetric-camellia192-roundtrip
# @title: gpg CAMELLIA192 symmetric round trip
# @description: Encrypts a payload with gpg --cipher-algo CAMELLIA192 and verifies the decrypted bytes match the original sha256 digest.
# @timeout: 180
# @tags: usage, gpg, crypto
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-symmetric-camellia192-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-camellia192-passphrase

printf 'camellia192 round trip payload\n' >"$tmpdir/plain.txt"
plain_sha=$(sha256sum "$tmpdir/plain.txt" | awk '{print $1}')

"${gpg_batch[@]}" --passphrase "$passphrase" --cipher-algo CAMELLIA192 \
  --symmetric -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
test -s "$tmpdir/plain.gpg"

"${gpg_batch[@]}" --passphrase "$passphrase" --decrypt \
  -o "$tmpdir/out.txt" "$tmpdir/plain.gpg"

out_sha=$(sha256sum "$tmpdir/out.txt" | awk '{print $1}')
test "$plain_sha" = "$out_sha"
cmp -s "$tmpdir/plain.txt" "$tmpdir/out.txt"
