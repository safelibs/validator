#!/usr/bin/env bash
# @testcase: usage-gpg-r9-detached-sign-verify-roundtrip
# @title: gpg detached sign and verify
# @description: Creates a detached binary signature for a payload and verifies it with --verify, asserting the verification status reports the signing key.
# @timeout: 240
# @tags: usage, gpg, sign
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

uid='Validator R9 <r9-dsv@example.invalid>'
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

printf 'detached payload bytes\n' >"$tmpdir/plain"
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --detach-sign -o "$tmpdir/plain.sig" "$tmpdir/plain"

[[ -s "$tmpdir/plain.sig" ]]

gpg --batch --verify "$tmpdir/plain.sig" "$tmpdir/plain" >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" 'Good signature'
validator_assert_contains "$tmpdir/out" 'r9-dsv@example.invalid'
