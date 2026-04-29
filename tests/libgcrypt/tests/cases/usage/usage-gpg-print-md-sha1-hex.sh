#!/usr/bin/env bash
# @testcase: usage-gpg-print-md-sha1-hex
# @title: gpg print-md SHA1
# @description: Computes a SHA1 digest with gpg --print-md and verifies a full hexadecimal digest is emitted.
# @timeout: 180
# @tags: usage, gpg, crypto
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-print-md-sha1-hex"
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

printf 'digest payload\n' >"$tmpdir/plain.txt"
gpg --print-md SHA1 "$tmpdir/plain.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'plain.txt:'
groups=$(grep -Eo '[0-9A-F]{4}' "$tmpdir/out" | wc -l)
test "$groups" -ge 10
