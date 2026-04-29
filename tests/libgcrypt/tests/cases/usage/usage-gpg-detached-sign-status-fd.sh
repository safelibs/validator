#!/usr/bin/env bash
# @testcase: usage-gpg-detached-sign-status-fd
# @title: gpg detached sign status-fd
# @description: Verifies a detached signature with gpg --status-fd and checks the machine-readable GOODSIG status output.
# @timeout: 180
# @tags: usage, gpg, signature
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-detached-sign-status-fd"
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
printf 'status payload\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --detach-sign -o "$tmpdir/plain.sig" "$tmpdir/plain.txt"
gpg --status-fd 1 --verify "$tmpdir/plain.sig" "$tmpdir/plain.txt" >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" '[GNUPG:] GOODSIG'
