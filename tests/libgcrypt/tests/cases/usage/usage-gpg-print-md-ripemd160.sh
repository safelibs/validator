#!/usr/bin/env bash
# @testcase: usage-gpg-print-md-ripemd160
# @title: gpg RIPEMD160 digest
# @description: Computes a RIPEMD160 message digest with gpg and verifies hexadecimal output is produced.
# @timeout: 180
# @tags: usage, crypto, digest
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-print-md-ripemd160"
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

printf 'digest payload\n' >"$tmpdir/plain.txt"
gpg --print-md RIPEMD160 "$tmpdir/plain.txt" >"$tmpdir/out"
grep -Eq '[0-9A-F]{4}' "$tmpdir/out"
