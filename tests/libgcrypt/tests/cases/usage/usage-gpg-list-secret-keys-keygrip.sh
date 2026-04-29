#!/usr/bin/env bash
# @testcase: usage-gpg-list-secret-keys-keygrip
# @title: gpg secret key keygrip listing
# @description: Lists secret keys with gpg --with-keygrip and verifies keygrip metadata is shown.
# @timeout: 180
# @tags: usage, gpg, keyring
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-list-secret-keys-keygrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-passphrase
uid='Validator Further <validator-further@example.invalid>'

make_signing_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1
}

make_signing_key
gpg --with-keygrip --list-secret-keys "$uid" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Keygrip'
