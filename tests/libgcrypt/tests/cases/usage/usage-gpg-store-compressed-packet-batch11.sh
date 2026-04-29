#!/usr/bin/env bash
# @testcase: usage-gpg-store-compressed-packet-batch11
# @title: gpg stored compressed packet
# @description: Stores a compressed OpenPGP packet and checks packet metadata with gpg.
# @timeout: 180
# @tags: usage, gpg, crypto
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-store-compressed-packet-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-passphrase
uid='Validator Batch11 <validator-batch11@example.invalid>'

make_signing_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1
}

make_encryption_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" rsa2048 encrypt 1d >/dev/null 2>&1
}

for _ in $(seq 1 40); do
  printf 'compressed packet payload\n'
done >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --compress-algo ZIP --store -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
gpg --list-packets "$tmpdir/plain.gpg" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'compressed packet'
