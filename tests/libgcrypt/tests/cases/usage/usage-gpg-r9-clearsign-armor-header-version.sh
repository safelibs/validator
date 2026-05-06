#!/usr/bin/env bash
# @testcase: usage-gpg-r9-clearsign-armor-header-version
# @title: gpg clearsign armor includes Hash header
# @description: Generates a clearsigned message and verifies the ASCII-armored output contains the Hash header documenting the digest algorithm.
# @timeout: 240
# @tags: usage, gpg, clearsign, armor
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

uid='Validator R9 <r9-cs@example.invalid>'
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

printf 'header line content\n' >"$tmpdir/plain"
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --digest-algo SHA256 --clearsign -o "$tmpdir/signed.asc" "$tmpdir/plain"

validator_assert_contains "$tmpdir/signed.asc" 'BEGIN PGP SIGNED MESSAGE'
validator_assert_contains "$tmpdir/signed.asc" 'Hash: SHA256'
