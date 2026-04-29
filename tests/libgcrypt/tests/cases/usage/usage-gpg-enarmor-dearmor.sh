#!/usr/bin/env bash
# @testcase: usage-gpg-enarmor-dearmor
# @title: gpg enarmor dearmor
# @description: Encodes a payload with gpg --enarmor, decodes it again, and verifies the original bytes round trip.
# @timeout: 180
# @tags: usage, gpg, crypto
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-enarmor-dearmor"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-passphrase
uid='Validator User <validator@example.invalid>'

make_signing_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1
}

make_encryption_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" rsa2048 encrypt 1d >/dev/null 2>&1
}

printf 'enarmor payload\n' >"$tmpdir/plain.txt"
gpg --enarmor <"$tmpdir/plain.txt" >"$tmpdir/plain.asc"
gpg --dearmor <"$tmpdir/plain.asc" >"$tmpdir/plain.bin"
cmp -s "$tmpdir/plain.txt" "$tmpdir/plain.bin"
