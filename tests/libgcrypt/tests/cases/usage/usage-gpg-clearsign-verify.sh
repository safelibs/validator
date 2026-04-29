#!/usr/bin/env bash
# @testcase: usage-gpg-clearsign-verify
# @title: GnuPG clear-signed message
# @description: Signs a message in cleartext form and verifies the resulting signature.
# @timeout: 180
# @tags: usage, crypto
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-clearsign-verify"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-passphrase
uid='Validator User <validator@example.invalid>'

make_signing_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1
}

make_encryption_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" rsa2048 encrypt 1d >/dev/null 2>&1
}

make_signing_key
printf 'clear signed payload\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --clearsign -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"
gpg --verify "$tmpdir/plain.asc" >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" 'Good signature'
