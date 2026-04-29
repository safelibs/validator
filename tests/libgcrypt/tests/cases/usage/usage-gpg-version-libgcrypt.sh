#!/usr/bin/env bash
# @testcase: usage-gpg-version-libgcrypt
# @title: GnuPG reports libgcrypt
# @description: Runs gpg --version and verifies it reports the linked libgcrypt version.
# @timeout: 120
# @tags: usage, crypto
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-version-libgcrypt"
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

gpg --version >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'libgcrypt'
