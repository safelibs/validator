#!/usr/bin/env bash
# @testcase: usage-gpg-export-ownertrust
# @title: gpg exports ownertrust
# @description: Imports ownertrust for a generated key and verifies gpg export-ownertrust writes the fingerprint record.
# @timeout: 180
# @tags: usage, crypto, trust
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-export-ownertrust"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-passphrase
uid='Validator More <validator-more@example.invalid>'

make_signing_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1
}

make_signing_key
fingerprint=$(gpg --with-colons --fingerprint "$uid" | awk -F: '$1 == "fpr" {print $10; exit}')
printf '%s:6:\n' "$fingerprint" | gpg --import-ownertrust >"$tmpdir/import.out" 2>&1
gpg --export-ownertrust >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" "$fingerprint"
