#!/usr/bin/env bash
# @testcase: usage-gpg-import-show-only
# @title: gpg import show-only
# @description: Inspects an exported public key with gpg import show-only mode and verifies public key metadata is displayed.
# @timeout: 180
# @tags: usage, gpg, keyring
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-import-show-only"
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
gpg --armor --export "$uid" >"$tmpdir/public.asc"
other_home="$tmpdir/other"
mkdir -p "$other_home"
chmod 700 "$other_home"
GNUPGHOME="$other_home" gpg --import-options show-only --dry-run --import "$tmpdir/public.asc" >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" 'pub'
