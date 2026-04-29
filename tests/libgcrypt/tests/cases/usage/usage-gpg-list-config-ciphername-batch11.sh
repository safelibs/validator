#!/usr/bin/env bash
# @testcase: usage-gpg-list-config-ciphername-batch11
# @title: gpg list config cipher names
# @description: Lists configured cipher algorithm names with gpg and checks TWOFISH support is reported.
# @timeout: 180
# @tags: usage, gpg, crypto
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-list-config-ciphername-batch11"
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

gpg --with-colons --list-config >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'cfg:ciphername:'
validator_assert_contains "$tmpdir/out" 'TWOFISH'
