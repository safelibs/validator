#!/usr/bin/env bash
# @testcase: usage-gpg-export-armor-block
# @title: gpg export armor block
# @description: Exports a generated public key in ASCII armor through gpg --armor --export and verifies the begin and end markers.
# @timeout: 180
# @tags: usage, gpg, export
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-export-armor-block"
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
gpg --armor --export "$uid" >"$tmpdir/pub.asc"
validator_assert_contains "$tmpdir/pub.asc" 'BEGIN PGP PUBLIC KEY BLOCK'
validator_assert_contains "$tmpdir/pub.asc" 'END PGP PUBLIC KEY BLOCK'
