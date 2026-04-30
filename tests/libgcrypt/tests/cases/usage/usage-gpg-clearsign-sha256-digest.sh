#!/usr/bin/env bash
# @testcase: usage-gpg-clearsign-sha256-digest
# @title: gpg clear-sign with explicit SHA256 digest header
# @description: Clear-signs a payload with --digest-algo SHA256, confirms gpg --verify reports a good signature, and checks that the armored block declares a Hash: SHA256 header.
# @timeout: 240
# @tags: usage, gpg, signature
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-clearsign-sha256-digest"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Validator Clearsign <validator-clearsign@example.invalid>'

"${gpg_batch[@]}" --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

printf 'clear sign sha256 payload\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --passphrase '' --digest-algo SHA256 --clear-sign \
  -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"

# The clear-signed armor must declare its hash and wrap the original text.
head -n 1 "$tmpdir/plain.asc" >"$tmpdir/clear-head"
validator_assert_contains "$tmpdir/clear-head" '-----BEGIN PGP SIGNED MESSAGE-----'
validator_assert_contains "$tmpdir/plain.asc" 'Hash: SHA256'
validator_assert_contains "$tmpdir/plain.asc" 'clear sign sha256 payload'
validator_assert_contains "$tmpdir/plain.asc" '-----BEGIN PGP SIGNATURE-----'
validator_assert_contains "$tmpdir/plain.asc" '-----END PGP SIGNATURE-----'

gpg --verify "$tmpdir/plain.asc" >"$tmpdir/verify" 2>&1
validator_assert_contains "$tmpdir/verify" 'Good signature'
