#!/usr/bin/env bash
# @testcase: usage-gpg-r12-clearsign-roundtrip-recovers-payload
# @title: gpg --clearsign output decrypts back to the original payload via --decrypt
# @description: Generates an Ed25519 signing key, runs --clearsign over a known payload, then runs gpg --decrypt against the clearsigned message and verifies the recovered plaintext matches the original byte-for-byte.
# @timeout: 240
# @tags: usage, gpg, clearsign, decrypt
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

uid='Validator R12 Clearsign <r12-clearsign@example.invalid>'
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

printf 'r12 clearsign payload\n' >"$tmpdir/plain.txt"

gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --clearsign -o "$tmpdir/signed.asc" "$tmpdir/plain.txt" >/dev/null 2>&1

validator_assert_contains "$tmpdir/signed.asc" 'BEGIN PGP SIGNED MESSAGE'

gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --decrypt "$tmpdir/signed.asc" >"$tmpdir/round.txt" 2>/dev/null

cmp "$tmpdir/plain.txt" "$tmpdir/round.txt"
