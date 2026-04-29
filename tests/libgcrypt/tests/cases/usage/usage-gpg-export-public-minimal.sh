#!/usr/bin/env bash
# @testcase: usage-gpg-export-public-minimal
# @title: gpg export minimal public key
# @description: Exports a minimal armored public key with gpg export options and verifies the ASCII armor header.
# @timeout: 180
# @tags: usage, gpg, keyring
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-export-public-minimal"
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
gpg --armor --export-options export-minimal --export "$uid" >"$tmpdir/public.asc"
validator_assert_contains "$tmpdir/public.asc" 'BEGIN PGP PUBLIC KEY BLOCK'
