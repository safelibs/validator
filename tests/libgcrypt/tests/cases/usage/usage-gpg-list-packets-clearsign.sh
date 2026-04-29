#!/usr/bin/env bash
# @testcase: usage-gpg-list-packets-clearsign
# @title: gpg list packets clearsign
# @description: Inspects a clearsigned message with gpg --list-packets and verifies a signature packet is reported.
# @timeout: 180
# @tags: usage, gpg, inspect
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-list-packets-clearsign"
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

make_signing_key
printf 'list packets clearsign\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --sign --armor -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"
"${gpg_batch[@]}" --list-packets "$tmpdir/plain.asc" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'signature packet'
