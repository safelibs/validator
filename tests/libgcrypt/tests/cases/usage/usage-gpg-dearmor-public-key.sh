#!/usr/bin/env bash
# @testcase: usage-gpg-dearmor-public-key
# @title: gpg dearmors public key
# @description: Dearmors an exported public key and verifies the binary keyring file is produced.
# @timeout: 180
# @tags: usage, crypto, keys
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-dearmor-public-key"
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
"${gpg_batch[@]}" --armor --export "$uid" >"$tmpdir/public.asc"
gpg --dearmor -o "$tmpdir/public.gpg" "$tmpdir/public.asc"
validator_require_file "$tmpdir/public.gpg"
test "$(wc -c <"$tmpdir/public.gpg")" -gt 0
