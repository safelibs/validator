#!/usr/bin/env bash
# @testcase: usage-gpg-armor-detached-sign
# @title: gpg armored detached signature
# @description: Creates an armored detached signature and verifies it with gpg.
# @timeout: 180
# @tags: usage, crypto, signature
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-armor-detached-sign"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-passphrase
uid='Validator Extra <validator-extra@example.invalid>'

make_signing_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1
}

make_encryption_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" rsa2048 encrypt 1d >/dev/null 2>&1
}

make_signing_key
printf 'armored signed payload\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --armor --detach-sign -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"
validator_assert_contains "$tmpdir/plain.asc" 'BEGIN PGP SIGNATURE'
gpg --verify "$tmpdir/plain.asc" "$tmpdir/plain.txt" >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" 'Good signature'
